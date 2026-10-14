# =============================================================================
# Diorite FrameArena 2D/3D Immediate Debug Batch Engine & Declarative Builder
# =============================================================================
# Upgrades `sol-vin/diorite` 2D and 3D immediate-mode debug drawing buffers to
# allocate per-frame vertex, color, and line batches directly from
# `Lapis::Core::FrameArena` with strictly zero Boehm GC heap allocations.
#
# Architecture (Two-Tier Engine & Declarative Builder Codex):
#   - Tier 1 (Core Engine):
#       * `Diorite::ArenaVertexBuffer(T)` — Stack-allocated struct backed by a
#         `Slice(T)` and an arena-allocated `Pointer(Int32)` size counter so
#         passing by value across `GeometryBuilder`, `ChartBuilder`, and
#         `TelemetryGraph` mutates the shared count in `FrameArena` memory
#         with zero heap allocations and zero boxing.
#       * `Diorite::FrameLineBatch3D` — Paired 3D vertex (`Vector3`) + color
#         (`Color`) arena buffers for immediate line-list construction.
#       * `Diorite::FrameLineBatch2D` — Paired 2D vertex (`Vector2`) + color
#         (`Color`) arena buffers for immediate canvas line-list construction.
#       * `Diorite::FrameDrawBuffers` — Complete per-frame 3D (on-top + depth)
#         and 2D immediate buffer suite carved from `Lapis::Core::FrameArena`,
#         capable of compiling an entire `DebugCommandQueue` in a single pass.
#   - Tier 2 (Declarative DSL):
#       * `Diorite::FrameBatchBuilder3D`, `Diorite::FrameBatchBuilder2D`, and
#         `Diorite::FrameBatchContext` — Ergonomic block receivers (`Diorite.frame`,
#         `DebugDraw.batch_3d`, `DebugDraw.batch_2d`) that emit geometry directly
#         into `Lapis::Core::FrameArena` scratchpad memory.
#
# Assigned Specialist: Theta (Godot Addons & Shaders Engineer)
# Work Order: WO-066 ([AS-3], RFC Discussion #113)
# =============================================================================

{% unless @top_level.has_constant?(:ZeroAllocation) %}
  annotation ZeroAllocation
  end

  annotation HotPath
  end

  annotation NoAlloc
  end

  annotation AllowAllocation
  end
{% end %}

{% unless ::Lapis.has_constant?(:Core) && ::Lapis::Core.has_constant?(:FrameArena) %}
  module Lapis
    module Core
      # Value-type telemetry snapshot of a `FrameArena` at a point in time.
      struct FrameArenaStats
        getter capacity : Int32
        getter offset : Int32
        getter remaining : Int32
        getter high_water_mark : Int32
        getter frame_count : UInt64
        getter allocation_count : Int32
        getter total_allocations : UInt64
        getter overflow_count : UInt64

        def initialize(
          @capacity : Int32,
          @offset : Int32,
          @remaining : Int32,
          @high_water_mark : Int32,
          @frame_count : UInt64,
          @allocation_count : Int32,
          @total_allocations : UInt64,
          @overflow_count : UInt64
        )
        end

        def utilization : Float64
          @capacity > 0 ? (@offset.to_f64 / @capacity.to_f64) : 0.0
        end

        def peak_utilization : Float64
          @capacity > 0 ? (@high_water_mark.to_f64 / @capacity.to_f64) : 0.0
        end
      end

      # Stack-allocated, zero-GC appendable typed buffer view backed by a `Slice(T)`
      # carved out of a `FrameArena`. Ideal for building per-frame vertex, color,
      # and line batches in `sol-vin/diorite` or signal argument scratch arrays.
      struct ArenaBuffer(T)
        getter raw_slice : Slice(T)
        getter size : Int32

        def initialize(@raw_slice : Slice(T), @size : Int32 = 0)
        end

        def self.from_slice(slice : Slice(T), size : Int32 = 0) : ArenaBuffer(T)
          new(slice, size)
        end

        @[ZeroAllocation]
        def capacity : Int32
          @raw_slice.size
        end

        @[ZeroAllocation]
        def remaining : Int32
          @raw_slice.size - @size
        end

        @[ZeroAllocation]
        def empty? : Bool
          @size == 0
        end

        @[ZeroAllocation]
        def full? : Bool
          @size >= @raw_slice.size
        end

        # Appends a single element to the arena buffer if space remains.
        # Returns true if written, false if capacity was reached.
        @[ZeroAllocation]
        def push(value : T) : Bool
          if @size < @raw_slice.size
            @raw_slice.to_unsafe[@size] = value
            @size += 1
            true
          else
            false
          end
        end

        # Fluent append operator (`buf << item`).
        @[ZeroAllocation]
        def <<(value : T) : self
          push(value)
          self
        end

        # Appends a pair of elements (e.g. start/end vertices for a 2D/3D line segment)
        # atomically if at least 2 slots remain.
        @[ZeroAllocation]
        def push_line(a : T, b : T) : Bool
          if @size + 2 <= @raw_slice.size
            ptr = @raw_slice.to_unsafe
            ptr[@size] = a
            ptr[@size + 1] = b
            @size += 2
            true
          else
            false
          end
        end

        @[ZeroAllocation]
        def unsafe_fetch(index : Int32) : T
          @raw_slice.to_unsafe[index]
        end

        @[ZeroAllocation]
        def [](index : Int32) : T
          @raw_slice.to_unsafe[index]
        end

        @[ZeroAllocation]
        def []?(index : Int32) : T?
          if index >= 0 && index < @size
            @raw_slice.to_unsafe[index]
          else
            nil
          end
        end

        @[ZeroAllocation]
        def []=(index : Int32, value : T) : T
          if index >= 0 && index < @size
            @raw_slice.to_unsafe[index] = value
          end
          value
        end

        # Resets the logical element count to 0 while retaining the underlying slice capacity.
        @[ZeroAllocation]
        def clear : self
          @size = 0
          self
        end

        # Returns a zero-allocation `Slice(T)` view over the written elements (`0...@size`).
        @[ZeroAllocation]
        def to_slice : Slice(T)
          Slice(T).new(@raw_slice.to_unsafe, @size)
        end

        @[ZeroAllocation]
        def to_unsafe : Pointer(T)
          @raw_slice.to_unsafe
        end

        @[ZeroAllocation]
        def each(& : T ->) : Nil
          i = 0
          ptr = @raw_slice.to_unsafe
          while i < @size
            yield ptr[i]
            i += 1
          end
        end
      end

      # Linear pointer-bump frame scratchpad allocator reset once per tick.
      #
      # All hot-path allocation methods (`alloc_bytes`, `alloc_slice`, `alloc_ptr`, `push`,
      # `copy_slice`, `copy_array`, `mark`, `rewind`, `reset!`, `tick!`) execute with
      # strictly ZERO GC heap allocations.
      class FrameArena
        DEFAULT_CAPACITY  = 1_048_576 # 1 MiB default frame scratchpad
        DEFAULT_ALIGNMENT =         8

        getter capacity : Int32
        getter offset : Int32 = 0
        getter high_water_mark : Int32 = 0
        getter frame_count : UInt64 = 0_u64
        getter allocation_count : Int32 = 0
        getter total_allocations : UInt64 = 0_u64
        getter overflow_count : UInt64 = 0_u64

        @buffer : Bytes

        @@current : FrameArena = FrameArena.new(DEFAULT_CAPACITY)

        # Returns the default active frame arena instance.
        @[ZeroAllocation]
        def self.current : FrameArena
          @@current
        end

        # Replaces or reconfigures the default frame arena with the given byte capacity.
        def self.configure(capacity : Int32 = DEFAULT_CAPACITY) : FrameArena
          @@current = FrameArena.new(capacity)
          @@current
        end

        # Resets the default frame arena for a new engine tick, incrementing its frame counter.
        @[ZeroAllocation]
        def self.tick! : FrameArena
          @@current.tick!
        end

        # Resets the default frame arena offset to zero without advancing the frame counter.
        @[ZeroAllocation]
        def self.reset! : FrameArena
          @@current.reset!
        end

        # Executes a block with the default frame arena and automatically calls `tick!` on completion.
        @[ZeroAllocation]
        def self.frame(&) : FrameArena
          arena = @@current
          begin
            yield arena
          ensure
            arena.tick!
          end
          arena
        end

        # Executes a scoped checkpoint block on the default frame arena, rewinding the bump pointer on exit.
        @[ZeroAllocation]
        def self.scope(&) : FrameArena
          arena = @@current
          m = arena.mark
          begin
            yield arena
          ensure
            arena.rewind(m)
          end
          arena
        end

        # Allocates a typed slice from the default frame arena.
        @[ZeroAllocation]
        def self.alloc_slice(type : T.class, count : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : Slice(T) forall T
          @@current.alloc_slice(T, count, alignment)
        end

        # Allocates an appendable `ArenaBuffer(T)` from the default frame arena.
        def self.buffer(type : T.class, capacity : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : ArenaBuffer(T) forall T
          @@current.buffer(T, capacity, alignment)
        end

        # Aligns `offset` upward to the nearest multiple of `alignment`.
        @[ZeroAllocation]
        def self.align_up(offset : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : Int32
          align = alignment > 1 ? alignment : 1
          mask = align - 1
          if (align & mask) == 0
            (offset + mask) & ~mask
          else
            rem = offset % align
            rem == 0 ? offset : offset + (align - rem)
          end
        end

        def initialize(capacity : Int32 = DEFAULT_CAPACITY)
          cap = capacity > 64 ? capacity : 64
          @capacity = cap
          @buffer = Bytes.new(cap)
        end

        @[ZeroAllocation]
        def used : Int32
          @offset
        end

        @[ZeroAllocation]
        def bytes_used : Int32
          @offset
        end

        @[ZeroAllocation]
        def remaining : Int32
          @capacity - @offset
        end

        @[ZeroAllocation]
        def bytes_remaining : Int32
          @capacity - @offset
        end

        @[ZeroAllocation]
        def peak_bytes : Int32
          @high_water_mark
        end

        @[ZeroAllocation]
        def tick_count : UInt64
          @frame_count
        end

        @[ZeroAllocation]
        def empty? : Bool
          @offset == 0
        end

        @[ZeroAllocation]
        def utilization : Float64
          @capacity > 0 ? (@offset.to_f64 / @capacity.to_f64) : 0.0
        end

        @[ZeroAllocation]
        def can_allocate?(size : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : Bool
          return false if size < 0
          return true if size == 0
          aligned = FrameArena.align_up(@offset, alignment)
          aligned + size <= @capacity
        end

        @[ZeroAllocation]
        def alloc_bytes(size : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : Bytes
          return Bytes.empty if size <= 0
          aligned = FrameArena.align_up(@offset, alignment)
          next_offset = aligned + size
          if next_offset > @capacity
            @overflow_count += 1_u64
            return Bytes.empty
          end

          @offset = next_offset
          if next_offset > @high_water_mark
            @high_water_mark = next_offset
          end
          @allocation_count += 1
          @total_allocations += 1_u64
          Bytes.new(@buffer.to_unsafe + aligned, size)
        end

        @[ZeroAllocation]
        def alloc_slice(type : T.class, count : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : Slice(T) forall T
          return Slice(T).empty if count <= 0
          elem_size = sizeof(T)
          byte_size = elem_size * count
          eff_align = alignment >= alignof(T) ? alignment : alignof(T)
          raw = alloc_bytes(byte_size, eff_align)
          return Slice(T).empty if raw.size < byte_size
          Slice(T).new(raw.to_unsafe.as(Pointer(T)), count)
        end

        @[ZeroAllocation]
        def alloc_slice(type : T.class, count : Int32, value : T, alignment : Int32 = DEFAULT_ALIGNMENT) : Slice(T) forall T
          s = alloc_slice(T, count, alignment)
          ptr = s.to_unsafe
          i = 0
          n = s.size
          while i < n
            ptr[i] = value
            i += 1
          end
          s
        end

        @[ZeroAllocation]
        def alloc_ptr(type : T.class, count : Int32 = 1, alignment : Int32 = DEFAULT_ALIGNMENT) : Pointer(T) forall T
          s = alloc_slice(T, count, alignment)
          s.empty? ? Pointer(T).null : s.to_unsafe
        end

        @[ZeroAllocation]
        def push(value : T, alignment : Int32 = DEFAULT_ALIGNMENT) : Pointer(T) forall T
          ptr = alloc_ptr(T, 1, alignment)
          unless ptr.null?
            ptr.value = value
          end
          ptr
        end

        @[ZeroAllocation]
        def copy_slice(src : Slice(T), alignment : Int32 = DEFAULT_ALIGNMENT) : Slice(T) forall T
          n = src.size
          return Slice(T).empty if n == 0
          dst = alloc_slice(T, n, alignment)
          return Slice(T).empty if dst.size < n
          src_ptr = src.to_unsafe
          dst_ptr = dst.to_unsafe
          i = 0
          while i < n
            dst_ptr[i] = src_ptr[i]
            i += 1
          end
          dst
        end

        @[ZeroAllocation]
        def copy_array(src : Array(T), alignment : Int32 = DEFAULT_ALIGNMENT) : Slice(T) forall T
          n = src.size
          return Slice(T).empty if n == 0
          dst = alloc_slice(T, n, alignment)
          return Slice(T).empty if dst.size < n
          src_ptr = src.to_unsafe
          dst_ptr = dst.to_unsafe
          i = 0
          while i < n
            dst_ptr[i] = src_ptr[i]
            i += 1
          end
          dst
        end

        def buffer(type : T.class, capacity : Int32, alignment : Int32 = DEFAULT_ALIGNMENT) : ArenaBuffer(T) forall T
          s = alloc_slice(T, capacity, alignment)
          ArenaBuffer(T).from_slice(s, 0)
        end

        @[ZeroAllocation]
        def mark : Int32
          @offset
        end

        @[ZeroAllocation]
        def rewind(mark_offset : Int32) : self
          if mark_offset >= 0 && mark_offset <= @offset
            @offset = mark_offset
          end
          self
        end

        @[ZeroAllocation]
        def scope(&) : self
          m = @offset
          begin
            yield self
          ensure
            @offset = m
          end
          self
        end

        @[ZeroAllocation]
        def frame(&) : self
          begin
            yield self
          ensure
            tick!
          end
          self
        end

        @[ZeroAllocation]
        def reset! : self
          @offset = 0
          @allocation_count = 0
          self
        end

        @[ZeroAllocation]
        def tick! : self
          @frame_count += 1_u64
          @offset = 0
          @allocation_count = 0
          self
        end

        @[ZeroAllocation]
        def tick : self
          tick!
        end

        @[ZeroAllocation]
        def clear! : self
          reset!
        end

        @[ZeroAllocation]
        def reset_stats! : self
          @offset = 0
          @high_water_mark = 0
          @frame_count = 0_u64
          @allocation_count = 0
          @total_allocations = 0_u64
          @overflow_count = 0_u64
          self
        end

        def stats : FrameArenaStats
          FrameArenaStats.new(
            capacity: @capacity,
            offset: @offset,
            remaining: @capacity - @offset,
            high_water_mark: @high_water_mark,
            frame_count: @frame_count,
            allocation_count: @allocation_count,
            total_allocations: @total_allocations,
            overflow_count: @overflow_count
          )
        end
      end
    end

    alias FrameArena = Core::FrameArena
    alias ArenaBuffer = Core::ArenaBuffer
    alias FrameArenaStats = Core::FrameArenaStats
  end

  module Godot
    alias FrameArena = ::Lapis::Core::FrameArena
    alias ArenaBuffer = ::Lapis::Core::ArenaBuffer
    alias FrameArenaStats = ::Lapis::Core::FrameArenaStats
  end
{% end %}

module Diorite
  # ===========================================================================
  # TIER 1: CORE ENGINE LAYER — FrameArena-Backed Vertex & Line Batch Buffers
  # ===========================================================================

  # Stack-allocated, pass-by-value vertex/color buffer view backed by a `Slice(T)`
  # and an arena-allocated `Pointer(Int32)` element counter carved out of
  # `Lapis::Core::FrameArena`.
  #
  # Because `@size_ptr` points to a 4-byte `Int32` slot in the `FrameArena`, passing
  # an `ArenaVertexBuffer(T)` by value into `GeometryBuilder`, `ChartBuilder`, and
  # `TelemetryGraph` methods mutates the shared element count in-place with
  # strictly zero heap allocations and zero struct boxing.
  struct ArenaVertexBuffer(T)
    getter raw_slice : Slice(T)
    getter size_ptr : Pointer(Int32)

    def initialize(@raw_slice : Slice(T), @size_ptr : Pointer(Int32))
    end

    # Carves an `ArenaVertexBuffer(T)` with `capacity` elements and an arena-backed
    # size counter directly from `arena`.
    def self.from_arena(
      arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
      capacity : Int32 = 1024,
      alignment : Int32 = Lapis::Core::FrameArena::DEFAULT_ALIGNMENT
    ) : ArenaVertexBuffer(T)
      s_ptr = arena.push(0_i32, 4)
      if s_ptr.null?
        new(Slice(T).empty, Pointer(Int32).null)
      else
        slice = arena.alloc_slice(T, capacity, alignment)
        new(slice, s_ptr)
      end
    end

    def self.from_parts(raw_slice : Slice(T), size_ptr : Pointer(Int32)) : ArenaVertexBuffer(T)
      new(raw_slice, size_ptr)
    end

    # Maximum number of elements this buffer can hold.
    @[ZeroAllocation]
    def capacity : Int32
      @raw_slice.size
    end

    # Current number of written elements.
    @[ZeroAllocation]
    def size : Int32
      @size_ptr.null? ? 0 : @size_ptr.value
    end

    # Remaining unwritten element slots.
    @[ZeroAllocation]
    def remaining : Int32
      @raw_slice.size - size
    end

    # Returns true if no elements have been written.
    @[ZeroAllocation]
    def empty? : Bool
      size == 0
    end

    # Returns true if the buffer has reached capacity.
    @[ZeroAllocation]
    def full? : Bool
      size >= @raw_slice.size
    end

    # Appends a single element to the arena buffer if space remains.
    @[ZeroAllocation]
    def push(value : T) : Bool
      s = @size_ptr.null? ? @raw_slice.size : @size_ptr.value
      if s < @raw_slice.size
        @raw_slice.to_unsafe[s] = value
        @size_ptr.value = s + 1
        true
      else
        false
      end
    end

    # Fluent append operator (`verts << pt`), drop-in compatible with `Array(T)#<<`.
    @[ZeroAllocation]
    def <<(value : T) : self
      push(value)
      self
    end

    # Appends a pair of elements (start/end vertices or colors for a line segment)
    # atomically if at least 2 slots remain.
    @[ZeroAllocation]
    def push_line(a : T, b : T) : Bool
      s = @size_ptr.null? ? @raw_slice.size : @size_ptr.value
      if s + 2 <= @raw_slice.size
        ptr = @raw_slice.to_unsafe
        ptr[s] = a
        ptr[s + 1] = b
        @size_ptr.value = s + 2
        true
      else
        false
      end
    end

    @[ZeroAllocation]
    def unsafe_fetch(index : Int32) : T
      @raw_slice.to_unsafe[index]
    end

    @[ZeroAllocation]
    def [](index : Int32) : T
      @raw_slice.to_unsafe[index]
    end

    @[ZeroAllocation]
    def []?(index : Int32) : T?
      s = size
      if index >= 0 && index < s
        @raw_slice.to_unsafe[index]
      else
        nil
      end
    end

    @[ZeroAllocation]
    def []=(index : Int32, value : T) : T
      s = size
      if index >= 0 && index < s
        @raw_slice.to_unsafe[index] = value
      end
      value
    end

    # Resets the logical element count to 0 while retaining the underlying arena slice.
    @[ZeroAllocation]
    def clear : self
      unless @size_ptr.null?
        @size_ptr.value = 0
      end
      self
    end

    # Returns a zero-allocation `Slice(T)` view over the written elements (`0...size`).
    @[ZeroAllocation]
    def to_slice : Slice(T)
      Slice(T).new(@raw_slice.to_unsafe, size)
    end

    # Returns a `Lapis::Core::ArenaBuffer(T)` snapshot of the written elements.
    def to_arena_buffer : Lapis::Core::ArenaBuffer(T)
      Lapis::Core::ArenaBuffer(T).from_slice(@raw_slice, size)
    end

    @[ZeroAllocation]
    def to_unsafe : Pointer(T)
      @raw_slice.to_unsafe
    end

    @[ZeroAllocation]
    def each(& : T ->) : Nil
      i = 0
      s = size
      ptr = @raw_slice.to_unsafe
      while i < s
        yield ptr[i]
        i += 1
      end
    end
  end

  # Stack-allocated 3D vertex and color batch buffer carved out of `Lapis::Core::FrameArena`.
  struct FrameLineBatch3D
    DEFAULT_CAPACITY = 8192

    getter verts : ArenaVertexBuffer(Godot::Vector3)
    getter cols : ArenaVertexBuffer(Godot::Color)

    def initialize(
      @verts : ArenaVertexBuffer(Godot::Vector3),
      @cols : ArenaVertexBuffer(Godot::Color)
    )
    end

    # Allocates a paired 3D vertex + color batch from `arena`.
    def self.from_arena(
      arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
      max_vertices : Int32 = DEFAULT_CAPACITY
    ) : FrameLineBatch3D
      v = ArenaVertexBuffer(Godot::Vector3).from_arena(arena, max_vertices)
      c = ArenaVertexBuffer(Godot::Color).from_arena(arena, v.capacity)
      new(v, c)
    end

    @[ZeroAllocation]
    def capacity : Int32
      @verts.capacity
    end

    @[ZeroAllocation]
    def vertex_count : Int32
      @verts.size
    end

    @[ZeroAllocation]
    def size : Int32
      @verts.size
    end

    @[ZeroAllocation]
    def line_count : Int32
      @verts.size // 2
    end

    @[ZeroAllocation]
    def remaining : Int32
      @verts.remaining
    end

    @[ZeroAllocation]
    def empty? : Bool
      @verts.empty?
    end

    @[ZeroAllocation]
    def full? : Bool
      @verts.full?
    end

    @[ZeroAllocation]
    def clear : self
      @verts.clear
      @cols.clear
      self
    end

    @[ZeroAllocation]
    def push_vertex(vertex : Godot::Vector3, color : Godot::Color) : Bool
      if @verts.push(vertex)
        @cols.push(color)
        true
      else
        false
      end
    end

    @[ZeroAllocation]
    def push_line(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color) : Bool
      if @verts.push_line(from, to)
        @cols.push_line(color, color)
        true
      else
        false
      end
    end

    @[ZeroAllocation]
    def push_line(from : Godot::Vector3, to : Godot::Vector3, from_color : Godot::Color, to_color : Godot::Color) : Bool
      if @verts.push_line(from, to)
        @cols.push_line(from_color, to_color)
        true
      else
        false
      end
    end

    # Zero-allocation `Slice(Godot::Vector3)` view over all written 3D vertices.
    @[ZeroAllocation]
    def vertices : Slice(Godot::Vector3)
      @verts.to_slice
    end

    # Zero-allocation `Slice(Godot::Color)` view over all written 3D vertex colors.
    @[ZeroAllocation]
    def colors : Slice(Godot::Color)
      @cols.to_slice
    end

    def vertex_arena_buffer : Lapis::Core::ArenaBuffer(Godot::Vector3)
      @verts.to_arena_buffer
    end

    def color_arena_buffer : Lapis::Core::ArenaBuffer(Godot::Color)
      @cols.to_arena_buffer
    end
  end

  # Stack-allocated 2D vertex and color batch buffer carved out of `Lapis::Core::FrameArena`.
  struct FrameLineBatch2D
    DEFAULT_CAPACITY = 4096

    getter verts : ArenaVertexBuffer(Godot::Vector2)
    getter cols : ArenaVertexBuffer(Godot::Color)

    def initialize(
      @verts : ArenaVertexBuffer(Godot::Vector2),
      @cols : ArenaVertexBuffer(Godot::Color)
    )
    end

    # Allocates a paired 2D vertex + color batch from `arena`.
    def self.from_arena(
      arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
      max_vertices : Int32 = DEFAULT_CAPACITY
    ) : FrameLineBatch2D
      v = ArenaVertexBuffer(Godot::Vector2).from_arena(arena, max_vertices)
      c = ArenaVertexBuffer(Godot::Color).from_arena(arena, v.capacity)
      new(v, c)
    end

    @[ZeroAllocation]
    def capacity : Int32
      @verts.capacity
    end

    @[ZeroAllocation]
    def vertex_count : Int32
      @verts.size
    end

    @[ZeroAllocation]
    def size : Int32
      @verts.size
    end

    @[ZeroAllocation]
    def line_count : Int32
      @verts.size // 2
    end

    @[ZeroAllocation]
    def remaining : Int32
      @verts.remaining
    end

    @[ZeroAllocation]
    def empty? : Bool
      @verts.empty?
    end

    @[ZeroAllocation]
    def full? : Bool
      @verts.full?
    end

    @[ZeroAllocation]
    def clear : self
      @verts.clear
      @cols.clear
      self
    end

    @[ZeroAllocation]
    def push_vertex(vertex : Godot::Vector2, color : Godot::Color) : Bool
      if @verts.push(vertex)
        @cols.push(color)
        true
      else
        false
      end
    end

    @[ZeroAllocation]
    def push_line(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color) : Bool
      if @verts.push_line(from, to)
        @cols.push_line(color, color)
        true
      else
        false
      end
    end

    @[ZeroAllocation]
    def push_line(from : Godot::Vector2, to : Godot::Vector2, from_color : Godot::Color, to_color : Godot::Color) : Bool
      if @verts.push_line(from, to)
        @cols.push_line(from_color, to_color)
        true
      else
        false
      end
    end

    # Zero-allocation `Slice(Godot::Vector2)` view over all written 2D vertices.
    @[ZeroAllocation]
    def vertices : Slice(Godot::Vector2)
      @verts.to_slice
    end

    # Zero-allocation `Slice(Godot::Color)` view over all written 2D vertex colors.
    @[ZeroAllocation]
    def colors : Slice(Godot::Color)
      @cols.to_slice
    end

    def vertex_arena_buffer : Lapis::Core::ArenaBuffer(Godot::Vector2)
      @verts.to_arena_buffer
    end

    def color_arena_buffer : Lapis::Core::ArenaBuffer(Godot::Color)
      @cols.to_arena_buffer
    end
  end

  # Complete suite of per-frame 3D (on-top + depth-tested) and 2D immediate-mode
  # debug vertex/color batches allocated from `Lapis::Core::FrameArena`.
  struct FrameDrawBuffers
    DEFAULT_ON_TOP_3D_CAPACITY = 8192
    DEFAULT_DEPTH_3D_CAPACITY  = 4096
    DEFAULT_2D_CAPACITY        = 4096

    getter batch_3d_on_top : FrameLineBatch3D
    getter batch_3d_depth : FrameLineBatch3D
    getter batch_2d : FrameLineBatch2D

    def initialize(
      @batch_3d_on_top : FrameLineBatch3D,
      @batch_3d_depth : FrameLineBatch3D,
      @batch_2d : FrameLineBatch2D
    )
    end

    # Carves a complete per-frame buffer set from `arena`.
    def self.from_arena(
      arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
      cap_3d_on_top : Int32 = DEFAULT_ON_TOP_3D_CAPACITY,
      cap_3d_depth : Int32 = DEFAULT_DEPTH_3D_CAPACITY,
      cap_2d : Int32 = DEFAULT_2D_CAPACITY
    ) : FrameDrawBuffers
      top = FrameLineBatch3D.from_arena(arena, cap_3d_on_top)
      depth = FrameLineBatch3D.from_arena(arena, cap_3d_depth)
      b2d = FrameLineBatch2D.from_arena(arena, cap_2d)
      new(top, depth, b2d)
    end

    @[ZeroAllocation]
    def verts_top : ArenaVertexBuffer(Godot::Vector3)
      @batch_3d_on_top.verts
    end

    @[ZeroAllocation]
    def cols_top : ArenaVertexBuffer(Godot::Color)
      @batch_3d_on_top.cols
    end

    @[ZeroAllocation]
    def verts_depth : ArenaVertexBuffer(Godot::Vector3)
      @batch_3d_depth.verts
    end

    @[ZeroAllocation]
    def cols_depth : ArenaVertexBuffer(Godot::Color)
      @batch_3d_depth.cols
    end

    @[ZeroAllocation]
    def verts_2d : ArenaVertexBuffer(Godot::Vector2)
      @batch_2d.verts
    end

    @[ZeroAllocation]
    def cols_2d : ArenaVertexBuffer(Godot::Color)
      @batch_2d.cols
    end

    @[ZeroAllocation]
    def total_vertices_3d : Int32
      @batch_3d_on_top.vertex_count + @batch_3d_depth.vertex_count
    end

    @[ZeroAllocation]
    def total_vertices_2d : Int32
      @batch_2d.vertex_count
    end

    @[ZeroAllocation]
    def total_vertex_count : Int32
      total_vertices_3d + total_vertices_2d
    end

    @[ZeroAllocation]
    def total_lines_3d : Int32
      @batch_3d_on_top.line_count + @batch_3d_depth.line_count
    end

    @[ZeroAllocation]
    def total_lines_2d : Int32
      @batch_2d.line_count
    end

    @[ZeroAllocation]
    def clear : self
      @batch_3d_on_top.clear
      @batch_3d_depth.clear
      @batch_2d.clear
      self
    end

    # Compiles a single `Command3D` into its target 3D arena batch.
    @[ZeroAllocation]
    def compile_command_3d(cmd : Command3D) : Void
      target_verts = cmd.on_top ? @batch_3d_on_top.verts : @batch_3d_depth.verts
      target_cols = cmd.on_top ? @batch_3d_on_top.cols : @batch_3d_depth.cols

      case cmd.kind
      when ShapeKind3D::Line
        GeometryBuilder.build_line(cmd.v0, cmd.v1, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Arrow, ShapeKind3D::LineArrow
        GeometryBuilder.build_arrow(cmd.v0, cmd.v1, cmd.color, cmd.f0, target_verts, target_cols)
      when ShapeKind3D::LinePath
        if !cmd.path_slice.empty?
          GeometryBuilder.build_line_path(cmd.path_slice, cmd.color, target_verts, target_cols)
        elsif p = cmd.path
          GeometryBuilder.build_line_path(p, cmd.color, target_verts, target_cols)
        end
      when ShapeKind3D::Box
        GeometryBuilder.build_box(cmd.v0, cmd.v1, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Sphere
        GeometryBuilder.build_sphere(cmd.v0, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Cylinder
        GeometryBuilder.build_cylinder(cmd.v0, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Capsule
        GeometryBuilder.build_capsule(cmd.v0, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Plane
        GeometryBuilder.build_plane(cmd.v0, cmd.v1, Godot::Vector2.new(cmd.f0, cmd.f1), cmd.color, target_verts, target_cols)
      when ShapeKind3D::Points
        if !cmd.path_slice.empty?
          GeometryBuilder.build_points(cmd.path_slice, cmd.f0, cmd.color, target_verts, target_cols)
        elsif p = cmd.path
          GeometryBuilder.build_points(p, cmd.f0, cmd.color, target_verts, target_cols)
        end
      when ShapeKind3D::Position3D
        GeometryBuilder.build_position_3d(cmd.v0, cmd.f0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Gizmo
        GeometryBuilder.build_gizmo(cmd.v0, cmd.basis, cmd.f0, target_verts, target_cols)
      when ShapeKind3D::Grid
        GeometryBuilder.build_grid(cmd.v0, Godot::Vector2.new(cmd.f0, cmd.f1), cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::CameraFrustum
        GeometryBuilder.build_camera_frustum(cmd.v0, cmd.basis, cmd.f0, cmd.f1, cmd.f2, cmd.f3, cmd.color, target_verts, target_cols)
      when ShapeKind3D::BillboardSquare
        GeometryBuilder.build_billboard_square(cmd.v0, cmd.f0, cmd.v1, cmd.color, target_verts, target_cols)
      when ShapeKind3D::RayHit
        GeometryBuilder.build_ray_hit(cmd.v0, cmd.v1, cmd.v2, cmd.color, target_verts, target_cols)
      when ShapeKind3D::TrajectoryArc
        GeometryBuilder.build_trajectory_arc(cmd.v0, cmd.v1, cmd.v2, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::VisionCone
        GeometryBuilder.build_vision_cone(cmd.v0, cmd.v1, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::OBB
        GeometryBuilder.build_obb(cmd.v0, cmd.v1, cmd.basis, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Spring
        GeometryBuilder.build_spring(cmd.v0, cmd.v1, cmd.f0, cmd.i0, cmd.i1, cmd.color, target_verts, target_cols)
      when ShapeKind3D::SurfaceDisk
        GeometryBuilder.build_surface_disk(cmd.v0, cmd.v1, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Ruler
        GeometryBuilder.build_ruler(cmd.v0, cmd.v1, cmd.f0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Reticle
        GeometryBuilder.build_reticle(cmd.v0, cmd.v1, cmd.f0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::SphereCast
        GeometryBuilder.build_sphere_cast(cmd.v0, cmd.v1, cmd.f0, cmd.hit, cmd.color, target_verts, target_cols)
      when ShapeKind3D::CapsuleCast
        GeometryBuilder.build_capsule_cast(cmd.v0, cmd.v1, cmd.f0, cmd.f1, cmd.hit, cmd.color, target_verts, target_cols)
      when ShapeKind3D::BoxCast
        GeometryBuilder.build_box_cast(cmd.v0, cmd.v1, cmd.v2, cmd.hit, cmd.color, target_verts, target_cols)
      when ShapeKind3D::BezierCubic
        GeometryBuilder.build_bezier_cubic(cmd.v0, cmd.v1, cmd.v2, cmd.v3, cmd.i0, cmd.color, target_verts, target_cols, cmd.wireframe)
      when ShapeKind3D::CatmullRom
        if !cmd.path_slice.empty?
          GeometryBuilder.build_catmull_rom(cmd.path_slice, cmd.i0, cmd.color, target_verts, target_cols, cmd.wireframe)
        elsif p = cmd.path
          GeometryBuilder.build_catmull_rom(p, cmd.i0, cmd.color, target_verts, target_cols, cmd.wireframe)
        end
      when ShapeKind3D::Cone3D
        GeometryBuilder.build_cone_3d(cmd.v0, cmd.v1, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::Circle3D
        GeometryBuilder.build_circle_3d(cmd.v0, cmd.v1, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
      when ShapeKind3D::ActorCard3D
        GeometryBuilder.build_actor_card_3d(cmd.v0, Godot::Vector2.new(cmd.f0, cmd.f1), cmd.color, target_verts, target_cols)
      when ShapeKind3D::PieChart3D
        if slices = cmd.pie_slices
          ChartBuilder.build_pie_chart_3d(cmd.v0, cmd.v1, cmd.f0, cmd.f1, slices, target_verts, target_cols)
        end
      when ShapeKind3D::Gauge3D
        ChartBuilder.build_gauge_3d(cmd.v0, cmd.v1, cmd.f0, cmd.f1, cmd.f2, cmd.f3, cmd.color, target_verts, target_cols)
      end
    end

    # Compiles a single `Command2D` into the 2D arena batch.
    @[ZeroAllocation]
    def compile_command_2d(cmd : Command2D) : Void
      v2d = @batch_2d.verts
      c2d = @batch_2d.cols

      case cmd.kind
      when ShapeKind2D::Line
        GeometryBuilder.build_line_2d(cmd.p0, cmd.p1, cmd.color, v2d, c2d)
      when ShapeKind2D::Arrow
        GeometryBuilder.build_arrow_2d(cmd.p0, cmd.p1, cmd.f0, cmd.color, v2d, c2d)
      when ShapeKind2D::Rect
        GeometryBuilder.build_rect_2d(cmd.rect, cmd.color, v2d, c2d)
      when ShapeKind2D::Circle
        GeometryBuilder.build_circle_2d(cmd.p0, cmd.f0, cmd.i0, cmd.color, v2d, c2d)
      when ShapeKind2D::Points
        if !cmd.points_slice.empty?
          GeometryBuilder.build_points_2d(cmd.points_slice, cmd.f0, cmd.color, v2d, c2d)
        elsif pts = cmd.points
          GeometryBuilder.build_points_2d(pts, cmd.f0, cmd.color, v2d, c2d)
        end
      when ShapeKind2D::Path
        if !cmd.points_slice.empty?
          GeometryBuilder.build_path_2d(cmd.points_slice, cmd.color, v2d, c2d)
        elsif pts = cmd.points
          GeometryBuilder.build_path_2d(pts, cmd.color, v2d, c2d)
        end
      when ShapeKind2D::Capsule
        GeometryBuilder.build_capsule_2d(cmd.p0, cmd.p1, cmd.f0, cmd.color, v2d, c2d, cmd.i0 > 0 ? cmd.i0 : 12)
      when ShapeKind2D::VisionCone
        GeometryBuilder.build_vision_cone_2d(cmd.p0, cmd.p1, cmd.f0, cmd.f1, cmd.i0 > 0 ? cmd.i0 : 16, cmd.color, v2d, c2d)
      when ShapeKind2D::Arc
        GeometryBuilder.build_arc_2d(cmd.p0, cmd.f0, cmd.f2, cmd.f3, cmd.i0 > 0 ? cmd.i0 : 24, cmd.color, v2d, c2d)
      when ShapeKind2D::Sector
        GeometryBuilder.build_sector_2d(cmd.p0, cmd.f0, cmd.f2, cmd.f3, cmd.i0 > 0 ? cmd.i0 : 24, cmd.color, v2d, c2d)
      when ShapeKind2D::Ruler
        GeometryBuilder.build_ruler_2d(cmd.p0, cmd.p1, cmd.color, v2d, c2d, cmd.f0 > 0 ? cmd.f0 : 20.0_f32, cmd.f1 > 0 ? cmd.f1 : 8.0_f32)
      when ShapeKind2D::PieChart
        if slices = cmd.pie_slices
          ChartBuilder.build_pie_chart_2d(cmd.p0, cmd.f0, cmd.f1, slices, v2d, c2d)
        end
      when ShapeKind2D::BarChart
        if bars = cmd.bar_data
          ChartBuilder.build_bar_chart_2d(cmd.rect, bars, cmd.b0, v2d, c2d)
        end
      when ShapeKind2D::Gauge
        ChartBuilder.build_gauge_2d(cmd.p0, cmd.f0, cmd.f1, cmd.f2, cmd.f3, cmd.color, v2d, c2d)
      end
    end

    # Compiles all enabled 3D commands from `queue` into `@batch_3d_on_top` and `@batch_3d_depth`.
    @[ZeroAllocation]
    def compile_3d(queue : DebugCommandQueue) : self
      cmds = queue.commands_3d
      i = 0
      n = cmds.size
      while i < n
        cmd = cmds.unsafe_fetch(i)
        if queue.channel_enabled?(cmd.channel)
          compile_command_3d(cmd)
        end
        i += 1
      end
      self
    end

    # Compiles all enabled 2D commands and telemetry graphs from `queue` into `@batch_2d`.
    @[ZeroAllocation]
    def compile_2d(queue : DebugCommandQueue) : self
      cmds = queue.commands_2d
      i = 0
      n = cmds.size
      while i < n
        cmd = cmds.unsafe_fetch(i)
        if queue.channel_enabled?(cmd.channel)
          compile_command_2d(cmd)
        end
        i += 1
      end

      v2d = @batch_2d.verts
      c2d = @batch_2d.cols
      queue.telemetry_graphs.each_value do |graph|
        graph.build_geometry(v2d, c2d)
      end
      self
    end

    # Compiles all enabled 3D commands, 2D commands, and telemetry graphs from `queue`
    # into these arena-backed buffers and updates the queue's vertex counters.
    @[ZeroAllocation]
    def compile_queue(queue : DebugCommandQueue) : self
      compile_3d(queue)
      compile_2d(queue)
      queue.verts_3d_last_frame = total_vertices_3d
      queue.verts_2d_last_frame = total_vertices_2d
      self
    end
  end

  module Core
    alias ArenaVertexBuffer = ::Diorite::ArenaVertexBuffer
    alias FrameLineBatch3D = ::Diorite::FrameLineBatch3D
    alias FrameLineBatch2D = ::Diorite::FrameLineBatch2D
    alias FrameDrawBuffers = ::Diorite::FrameDrawBuffers
  end

  # ===========================================================================
  # TIER 2: DECLARATIVE DSL LAYER — Zero-Allocation Immediate Batch Builders
  # ===========================================================================

  # Ergonomic 3D immediate batch builder writing directly into a `FrameLineBatch3D`
  # carved out of `Lapis::Core::FrameArena`.
  struct FrameBatchBuilder3D
    DEFAULT_COLOR      = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)
    DEFAULT_GRID_COLOR = Godot::Color.new(0.6_f32, 0.6_f32, 0.6_f32, 0.5_f32)

    getter batch : FrameLineBatch3D

    def initialize(@batch : FrameLineBatch3D)
    end

    def self.wrap(batch : FrameLineBatch3D) : FrameBatchBuilder3D
      new(batch)
    end

    @[ZeroAllocation]
    def verts : ArenaVertexBuffer(Godot::Vector3)
      @batch.verts
    end

    @[ZeroAllocation]
    def cols : ArenaVertexBuffer(Godot::Color)
      @batch.cols
    end

    @[ZeroAllocation]
    def vertex_count : Int32
      @batch.vertex_count
    end

    @[ZeroAllocation]
    def line_count : Int32
      @batch.line_count
    end

    @[ZeroAllocation]
    def vertices : Slice(Godot::Vector3)
      @batch.vertices
    end

    @[ZeroAllocation]
    def colors : Slice(Godot::Color)
      @batch.colors
    end

    @[ZeroAllocation]
    def line(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_line(from, to, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def line_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR) : self
      line(from, to, color)
    end

    @[ZeroAllocation]
    def arrow(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 0.25_f32) : self
      GeometryBuilder.build_arrow(from, to, color, head_size, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 0.25_f32) : self
      arrow(from, to, color, head_size)
    end

    @[ZeroAllocation]
    def line_path(points, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_line_path(points, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def line_path_3d(points, color : Godot::Color = DEFAULT_COLOR) : self
      line_path(points, color)
    end

    @[ZeroAllocation]
    def box(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_box(center, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def box(aabb : Godot::AABB, color : Godot::Color = DEFAULT_COLOR) : self
      center = aabb.position + aabb.size * 0.5_f32
      GeometryBuilder.build_box(center, aabb.size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def box_3d(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR) : self
      box(center, size, color)
    end

    @[ZeroAllocation]
    def sphere(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = DEFAULT_COLOR, rings : Int32 = 16) : self
      GeometryBuilder.build_sphere(center, radius, rings, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def sphere_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = DEFAULT_COLOR, rings : Int32 = 16) : self
      sphere(center, radius, color, rings)
    end

    @[ZeroAllocation]
    def cylinder(center : Godot::Vector3, radius : Float32 = 1.0_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16) : self
      GeometryBuilder.build_cylinder(center, radius, height, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def cylinder_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16) : self
      cylinder(center, radius, height, color, segments)
    end

    @[ZeroAllocation]
    def capsule(center : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16) : self
      GeometryBuilder.build_capsule(center, radius, height, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def capsule_3d(center : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16) : self
      capsule(center, radius, height, color, segments)
    end

    @[ZeroAllocation]
    def plane(center : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32), size : Godot::Vector2 = Godot::Vector2.new(5.0_f32, 5.0_f32), color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_plane(center, normal, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def plane_3d(center : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32), size : Godot::Vector2 = Godot::Vector2.new(5.0_f32, 5.0_f32), color : Godot::Color = DEFAULT_COLOR) : self
      plane(center, normal, size, color)
    end

    @[ZeroAllocation]
    def points(pts, size : Float32 = 0.1_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_points(pts, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def points_3d(pts, size : Float32 = 0.1_f32, color : Godot::Color = DEFAULT_COLOR) : self
      points(pts, size, color)
    end

    @[ZeroAllocation]
    def position_3d(origin : Godot::Vector3, size : Float32 = 1.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_position_3d(origin, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def gizmo(origin : Godot::Vector3, basis : Godot::Basis = Godot::Basis.new, size : Float32 = 1.0_f32) : self
      GeometryBuilder.build_gizmo(origin, basis, size, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def gizmo_3d(origin : Godot::Vector3, basis : Godot::Basis = Godot::Basis.new, size : Float32 = 1.0_f32) : self
      gizmo(origin, basis, size)
    end

    @[ZeroAllocation]
    def grid(center : Godot::Vector3 = Godot::Vector3.new, size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32), subdivisions : Int32 = 10, color : Godot::Color = DEFAULT_GRID_COLOR) : self
      GeometryBuilder.build_grid(center, size, subdivisions, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def grid_3d(center : Godot::Vector3 = Godot::Vector3.new, size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32), subdivisions : Int32 = 10, color : Godot::Color = DEFAULT_GRID_COLOR) : self
      grid(center, size, subdivisions, color)
    end

    @[ZeroAllocation]
    def camera_frustum(origin : Godot::Vector3, basis : Godot::Basis, fov_deg : Float32 = 75.0_f32, near : Float32 = 0.05_f32, far : Float32 = 10.0_f32, aspect : Float32 = 1.777_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_camera_frustum(origin, basis, fov_deg, near, far, aspect, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def billboard_square(position : Godot::Vector3, size : Float32 = 1.0_f32, camera_pos : Godot::Vector3 = Godot::Vector3.new, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_billboard_square(position, size, camera_pos, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def ray_hit(origin : Godot::Vector3, hit_point : Godot::Vector3, normal : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_ray_hit(origin, hit_point, normal, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def trajectory_arc(origin : Godot::Vector3, velocity : Godot::Vector3, gravity : Godot::Vector3 = Godot::Vector3.new(0.0_f32, -9.8_f32, 0.0_f32), max_time : Float32 = 3.0_f32, steps : Int32 = 40, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_trajectory_arc(origin, velocity, gravity, max_time, steps, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def vision_cone(origin : Godot::Vector3, direction : Godot::Vector3, angle_deg : Float32 = 45.0_f32, range : Float32 = 10.0_f32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_vision_cone(origin, direction, angle_deg, range, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def obb(center : Godot::Vector3, size : Godot::Vector3, basis : Godot::Basis, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_obb(center, size, basis, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def spring(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.2_f32, coils : Int32 = 8, segments : Int32 = 16, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_spring(from, to, radius, coils, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def surface_disk(position : Godot::Vector3, normal : Godot::Vector3, radius : Float32 = 0.5_f32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_surface_disk(position, normal, radius, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def ruler(from : Godot::Vector3, to : Godot::Vector3, tick_size : Float32 = 0.2_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_ruler(from, to, tick_size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def reticle(position : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32), size : Float32 = 0.5_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_reticle(position, normal, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def sphere_cast(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.5_f32, hit : Bool = false, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_sphere_cast(from, to, radius, hit, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def capsule_cast(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 1.8_f32, hit : Bool = false, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_capsule_cast(from, to, radius, height, hit, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def box_cast(from : Godot::Vector3, to : Godot::Vector3, size : Godot::Vector3 = Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32), hit : Bool = false, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_box_cast(from, to, size, hit, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def bezier_cubic(p0 : Godot::Vector3, p1 : Godot::Vector3, p2 : Godot::Vector3, p3 : Godot::Vector3, segments : Int32 = 32, color : Godot::Color = DEFAULT_COLOR, show_hull : Bool = true) : self
      GeometryBuilder.build_bezier_cubic(p0, p1, p2, p3, segments, color, @batch.verts, @batch.cols, show_hull)
      self
    end

    @[ZeroAllocation]
    def catmull_rom(points, segments_per_curve : Int32 = 16, color : Godot::Color = DEFAULT_COLOR, loop : Bool = false) : self
      GeometryBuilder.build_catmull_rom(points, segments_per_curve, color, @batch.verts, @batch.cols, loop)
      self
    end

    @[ZeroAllocation]
    def cone_3d(tip : Godot::Vector3, dir : Godot::Vector3, length : Float32 = 5.0_f32, angle_rad : Float32 = 0.52359877_f32, segments : Int32 = 16, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_cone_3d(tip, dir, length, angle_rad, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def circle_3d(center : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32), radius : Float32 = 1.0_f32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_circle_3d(center, normal, radius, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def actor_card_3d(position : Godot::Vector3, size : Godot::Vector2 = Godot::Vector2.new(1.2_f32, 0.8_f32), color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_actor_card_3d(position, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def pie_chart_3d(center : Godot::Vector3, normal : Godot::Vector3, radius : Float32, slices : Array(PieSlice), inner_radius : Float32 = 0.0_f32) : self
      ChartBuilder.build_pie_chart_3d(center, normal, radius, inner_radius, slices, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def gauge_3d(center : Godot::Vector3, normal : Godot::Vector3, radius : Float32, value : Float32, min_val : Float32 = 0.0_f32, max_val : Float32 = 100.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      ChartBuilder.build_gauge_3d(center, normal, radius, value, min_val, max_val, color, @batch.verts, @batch.cols)
      self
    end
  end

  # Ergonomic 2D immediate batch builder writing directly into a `FrameLineBatch2D`
  # carved out of `Lapis::Core::FrameArena`.
  struct FrameBatchBuilder2D
    DEFAULT_COLOR = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)

    getter batch : FrameLineBatch2D

    def initialize(@batch : FrameLineBatch2D)
    end

    def self.wrap(batch : FrameLineBatch2D) : FrameBatchBuilder2D
      new(batch)
    end

    @[ZeroAllocation]
    def verts : ArenaVertexBuffer(Godot::Vector2)
      @batch.verts
    end

    @[ZeroAllocation]
    def cols : ArenaVertexBuffer(Godot::Color)
      @batch.cols
    end

    @[ZeroAllocation]
    def vertex_count : Int32
      @batch.vertex_count
    end

    @[ZeroAllocation]
    def line_count : Int32
      @batch.line_count
    end

    @[ZeroAllocation]
    def vertices : Slice(Godot::Vector2)
      @batch.vertices
    end

    @[ZeroAllocation]
    def colors : Slice(Godot::Color)
      @batch.colors
    end

    @[ZeroAllocation]
    def line(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_line_2d(from, to, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def line_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR) : self
      line(from, to, color)
    end

    @[ZeroAllocation]
    def arrow(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 10.0_f32) : self
      GeometryBuilder.build_arrow_2d(from, to, head_size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def arrow_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 10.0_f32) : self
      arrow(from, to, color, head_size)
    end

    @[ZeroAllocation]
    def rect(r : Godot::Rect2, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_rect_2d(r, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def rect_2d(r : Godot::Rect2, color : Godot::Color = DEFAULT_COLOR) : self
      rect(r, color)
    end

    @[ZeroAllocation]
    def circle(center : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 24) : self
      GeometryBuilder.build_circle_2d(center, radius, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def circle_2d(center : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 24) : self
      circle(center, radius, color, segments)
    end

    @[ZeroAllocation]
    def points(pts, size : Float32 = 4.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_points_2d(pts, size, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def points_2d(pts, size : Float32 = 4.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      points(pts, size, color)
    end

    @[ZeroAllocation]
    def path(pts, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_path_2d(pts, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def path_2d(pts, color : Godot::Color = DEFAULT_COLOR) : self
      path(pts, color)
    end

    @[ZeroAllocation]
    def capsule(p0 : Godot::Vector2, p1 : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 12) : self
      GeometryBuilder.build_capsule_2d(p0, p1, radius, color, @batch.verts, @batch.cols, segments)
      self
    end

    @[ZeroAllocation]
    def capsule_2d(p0 : Godot::Vector2, p1 : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 12) : self
      capsule(p0, p1, radius, color, segments)
    end

    @[ZeroAllocation]
    def vision_cone(origin : Godot::Vector2, dir : Godot::Vector2, distance : Float32, angle_rad : Float32, segments : Int32 = 16, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_vision_cone_2d(origin, dir, distance, angle_rad, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def vision_cone_2d(origin : Godot::Vector2, dir : Godot::Vector2, distance : Float32, angle_rad : Float32, segments : Int32 = 16, color : Godot::Color = DEFAULT_COLOR) : self
      vision_cone(origin, dir, distance, angle_rad, segments, color)
    end

    @[ZeroAllocation]
    def arc(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_arc_2d(center, radius, start_angle, end_angle, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def arc_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      arc(center, radius, start_angle, end_angle, segments, color)
    end

    @[ZeroAllocation]
    def sector(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      GeometryBuilder.build_sector_2d(center, radius, start_angle, end_angle, segments, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def sector_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      sector(center, radius, start_angle, end_angle, segments, color)
    end

    @[ZeroAllocation]
    def ruler(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, tick_step : Float32 = 20.0_f32, tick_size : Float32 = 8.0_f32) : self
      GeometryBuilder.build_ruler_2d(from, to, color, @batch.verts, @batch.cols, tick_step, tick_size)
      self
    end

    @[ZeroAllocation]
    def ruler_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, tick_step : Float32 = 20.0_f32, tick_size : Float32 = 8.0_f32) : self
      ruler(from, to, color, tick_step, tick_size)
      self
    end

    @[ZeroAllocation]
    def pie_chart(center : Godot::Vector2, radius : Float32, slices : Array(PieSlice), inner_radius : Float32 = 0.0_f32) : self
      ChartBuilder.build_pie_chart_2d(center, radius, inner_radius, slices, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def pie_chart_2d(center : Godot::Vector2, radius : Float32, slices : Array(PieSlice), inner_radius : Float32 = 0.0_f32) : self
      pie_chart(center, radius, slices, inner_radius)
    end

    @[ZeroAllocation]
    def bar_chart(r : Godot::Rect2, bars : Array(BarData), horizontal : Bool = false) : self
      ChartBuilder.build_bar_chart_2d(r, bars, horizontal, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def bar_chart_2d(r : Godot::Rect2, bars : Array(BarData), horizontal : Bool = false) : self
      bar_chart(r, bars, horizontal)
    end

    @[ZeroAllocation]
    def gauge(center : Godot::Vector2, radius : Float32, value : Float32, min_val : Float32 = 0.0_f32, max_val : Float32 = 100.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      ChartBuilder.build_gauge_2d(center, radius, value, min_val, max_val, color, @batch.verts, @batch.cols)
      self
    end

    @[ZeroAllocation]
    def gauge_2d(center : Godot::Vector2, radius : Float32, value : Float32, min_val : Float32 = 0.0_f32, max_val : Float32 = 100.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      gauge(center, radius, value, min_val, max_val, color)
    end

    @[ZeroAllocation]
    def telemetry_graph(graph : TelemetryGraph) : self
      graph.build_geometry(@batch.verts, @batch.cols)
      self
    end
  end

  # Unified 2D/3D zero-allocation frame batch builder yielded by `Diorite.frame { |batch| ... }`.
  #
  # ```crystal
  # Diorite.frame do |batch|
  #   batch.line(from, to, color)
  #   batch.box(aabb, color)
  #   batch.circle_2d(center_2d, 32.0_f32, color)
  # end
  # ```
  struct FrameBatchContext
    DEFAULT_COLOR      = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)
    DEFAULT_GRID_COLOR = Godot::Color.new(0.6_f32, 0.6_f32, 0.6_f32, 0.5_f32)

    getter buffers : FrameDrawBuffers
    getter on_top_3d : FrameBatchBuilder3D
    getter depth_3d : FrameBatchBuilder3D
    getter canvas_2d : FrameBatchBuilder2D

    def initialize(@buffers : FrameDrawBuffers)
      @on_top_3d = FrameBatchBuilder3D.wrap(@buffers.batch_3d_on_top)
      @depth_3d = FrameBatchBuilder3D.wrap(@buffers.batch_3d_depth)
      @canvas_2d = FrameBatchBuilder2D.wrap(@buffers.batch_2d)
    end

    def self.wrap(buffers : FrameDrawBuffers) : FrameBatchContext
      new(buffers)
    end

    @[ZeroAllocation]
    def total_vertices_3d : Int32
      @buffers.total_vertices_3d
    end

    @[ZeroAllocation]
    def total_vertices_2d : Int32
      @buffers.total_vertices_2d
    end

    @[ZeroAllocation]
    def total_lines_3d : Int32
      @buffers.total_lines_3d
    end

    @[ZeroAllocation]
    def total_lines_2d : Int32
      @buffers.total_lines_2d
    end

    @[ZeroAllocation]
    def draw_3d(on_top : Bool = true, & : FrameBatchBuilder3D ->) : self
      if on_top
        yield @on_top_3d
      else
        yield @depth_3d
      end
      self
    end

    @[ZeroAllocation]
    def draw_2d(& : FrameBatchBuilder2D ->) : self
      yield @canvas_2d
      self
    end

    # ── 3D Immediate Batch Operations ───────────────────────────────────────

    @[ZeroAllocation]
    def line(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      if on_top
        @on_top_3d.line(from, to, color)
      else
        @depth_3d.line(from, to, color)
      end
      self
    end

    @[ZeroAllocation]
    def line_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      line(from, to, color, on_top)
    end

    @[ZeroAllocation]
    def arrow(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 0.25_f32, on_top : Bool = true) : self
      if on_top
        @on_top_3d.arrow(from, to, color, head_size)
      else
        @depth_3d.arrow(from, to, color, head_size)
      end
      self
    end

    @[ZeroAllocation]
    def arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 0.25_f32, on_top : Bool = true) : self
      arrow(from, to, color, head_size, on_top)
    end

    @[ZeroAllocation]
    def line_path(points, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      if on_top
        @on_top_3d.line_path(points, color)
      else
        @depth_3d.line_path(points, color)
      end
      self
    end

    @[ZeroAllocation]
    def line_path_3d(points, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      line_path(points, color, on_top)
    end

    @[ZeroAllocation]
    def box(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      if on_top
        @on_top_3d.box(center, size, color)
      else
        @depth_3d.box(center, size, color)
      end
      self
    end

    @[ZeroAllocation]
    def box(aabb : Godot::AABB, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      if on_top
        @on_top_3d.box(aabb, color)
      else
        @depth_3d.box(aabb, color)
      end
      self
    end

    @[ZeroAllocation]
    def box_3d(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = DEFAULT_COLOR, on_top : Bool = true) : self
      box(center, size, color, on_top)
    end

    @[ZeroAllocation]
    def sphere(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = DEFAULT_COLOR, rings : Int32 = 16, on_top : Bool = true) : self
      if on_top
        @on_top_3d.sphere(center, radius, color, rings)
      else
        @depth_3d.sphere(center, radius, color, rings)
      end
      self
    end

    @[ZeroAllocation]
    def sphere_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = DEFAULT_COLOR, rings : Int32 = 16, on_top : Bool = true) : self
      sphere(center, radius, color, rings, on_top)
    end

    @[ZeroAllocation]
    def cylinder(center : Godot::Vector3, radius : Float32 = 1.0_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16, on_top : Bool = true) : self
      if on_top
        @on_top_3d.cylinder(center, radius, height, color, segments)
      else
        @depth_3d.cylinder(center, radius, height, color, segments)
      end
      self
    end

    @[ZeroAllocation]
    def cylinder_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16, on_top : Bool = true) : self
      cylinder(center, radius, height, color, segments, on_top)
    end

    @[ZeroAllocation]
    def capsule(center : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16, on_top : Bool = true) : self
      if on_top
        @on_top_3d.capsule(center, radius, height, color, segments)
      else
        @depth_3d.capsule(center, radius, height, color, segments)
      end
      self
    end

    @[ZeroAllocation]
    def capsule_3d(center : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 2.0_f32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 16, on_top : Bool = true) : self
      capsule(center, radius, height, color, segments, on_top)
    end

    @[ZeroAllocation]
    def gizmo(origin : Godot::Vector3, basis : Godot::Basis = Godot::Basis.new, size : Float32 = 1.0_f32, on_top : Bool = true) : self
      if on_top
        @on_top_3d.gizmo(origin, basis, size)
      else
        @depth_3d.gizmo(origin, basis, size)
      end
      self
    end

    @[ZeroAllocation]
    def gizmo_3d(origin : Godot::Vector3, basis : Godot::Basis = Godot::Basis.new, size : Float32 = 1.0_f32, on_top : Bool = true) : self
      gizmo(origin, basis, size, on_top)
    end

    @[ZeroAllocation]
    def grid(center : Godot::Vector3 = Godot::Vector3.new, size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32), subdivisions : Int32 = 10, color : Godot::Color = DEFAULT_GRID_COLOR, on_top : Bool = true) : self
      if on_top
        @on_top_3d.grid(center, size, subdivisions, color)
      else
        @depth_3d.grid(center, size, subdivisions, color)
      end
      self
    end

    @[ZeroAllocation]
    def grid_3d(center : Godot::Vector3 = Godot::Vector3.new, size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32), subdivisions : Int32 = 10, color : Godot::Color = DEFAULT_GRID_COLOR, on_top : Bool = true) : self
      grid(center, size, subdivisions, color, on_top)
    end

    # ── 2D Immediate Batch Operations ───────────────────────────────────────

    @[ZeroAllocation]
    def line_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.line(from, to, color)
      self
    end

    @[ZeroAllocation]
    def arrow_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, head_size : Float32 = 10.0_f32) : self
      @canvas_2d.arrow(from, to, color, head_size)
      self
    end

    @[ZeroAllocation]
    def rect_2d(r : Godot::Rect2, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.rect(r, color)
      self
    end

    @[ZeroAllocation]
    def circle_2d(center : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 24) : self
      @canvas_2d.circle(center, radius, color, segments)
      self
    end

    @[ZeroAllocation]
    def points_2d(pts, size : Float32 = 4.0_f32, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.points(pts, size, color)
      self
    end

    @[ZeroAllocation]
    def path_2d(pts, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.path(pts, color)
      self
    end

    @[ZeroAllocation]
    def capsule_2d(p0 : Godot::Vector2, p1 : Godot::Vector2, radius : Float32, color : Godot::Color = DEFAULT_COLOR, segments : Int32 = 12) : self
      @canvas_2d.capsule(p0, p1, radius, color, segments)
      self
    end

    @[ZeroAllocation]
    def vision_cone_2d(origin : Godot::Vector2, dir : Godot::Vector2, distance : Float32, angle_rad : Float32, segments : Int32 = 16, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.vision_cone(origin, dir, distance, angle_rad, segments, color)
      self
    end

    @[ZeroAllocation]
    def arc_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.arc(center, radius, start_angle, end_angle, segments, color)
      self
    end

    @[ZeroAllocation]
    def sector_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = DEFAULT_COLOR) : self
      @canvas_2d.sector(center, radius, start_angle, end_angle, segments, color)
      self
    end

    @[ZeroAllocation]
    def ruler_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = DEFAULT_COLOR, tick_step : Float32 = 20.0_f32, tick_size : Float32 = 8.0_f32) : self
      @canvas_2d.ruler(from, to, color, tick_step, tick_size)
      self
    end

    @[ZeroAllocation]
    def telemetry_graph(graph : TelemetryGraph) : self
      @canvas_2d.telemetry_graph(graph)
      self
    end
  end

  # Carves per-frame 2D/3D vertex and line batches from `Lapis::Core::FrameArena`
  # and yields a `FrameBatchContext` for immediate zero-allocation geometry assembly.
  #
  # ```crystal
  # Diorite.frame do |batch|
  #   batch.line(from, to, color)
  #   batch.box(aabb, color)
  # end
  # ```
  def self.frame(
    arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
    cap_3d_on_top : Int32 = FrameDrawBuffers::DEFAULT_ON_TOP_3D_CAPACITY,
    cap_3d_depth : Int32 = FrameDrawBuffers::DEFAULT_DEPTH_3D_CAPACITY,
    cap_2d : Int32 = FrameDrawBuffers::DEFAULT_2D_CAPACITY,
    & : FrameBatchContext ->
  ) : FrameDrawBuffers
    buffers = FrameDrawBuffers.from_arena(arena, cap_3d_on_top, cap_3d_depth, cap_2d)
    ctx = FrameBatchContext.wrap(buffers)
    yield ctx
    buffers
  end

  # Executes a scoped `Diorite.frame` batch inside `arena.scope`, automatically
  # rewinding the `FrameArena` bump pointer when the block completes.
  def self.scoped_frame(
    arena : Lapis::Core::FrameArena = Lapis::Core::FrameArena.current,
    cap_3d_on_top : Int32 = FrameDrawBuffers::DEFAULT_ON_TOP_3D_CAPACITY,
    cap_3d_depth : Int32 = FrameDrawBuffers::DEFAULT_DEPTH_3D_CAPACITY,
    cap_2d : Int32 = FrameDrawBuffers::DEFAULT_2D_CAPACITY,
    & : FrameBatchContext ->
  ) : Void
    arena.scope do |scoped_arena|
      buffers = FrameDrawBuffers.from_arena(scoped_arena, cap_3d_on_top, cap_3d_depth, cap_2d)
      ctx = FrameBatchContext.wrap(buffers)
      yield ctx
    end
  end
end
