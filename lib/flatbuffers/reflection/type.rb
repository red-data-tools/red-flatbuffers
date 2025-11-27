# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "base_type"

module FlatBuffers
  module Reflection
    class Type < ::FlatBuffers::Table
      # The size (octets) of the `base_type` field.
      def base_size
        field_offset = @view.unpack_virtual_offset(12)
        return 4 if field_offset.zero?

        @view.unpack_uint(field_offset)
      end

      def base_type
        field_offset = @view.unpack_virtual_offset(4)
        if field_offset.zero?
          enum_value = 0
        else
          enum_value = @view.unpack_byte(field_offset)
        end
        BaseType.try_convert(enum_value) || enum_value
      end

      def element
        field_offset = @view.unpack_virtual_offset(6)
        if field_offset.zero?
          enum_value = 0
        else
          enum_value = @view.unpack_byte(field_offset)
        end
        BaseType.try_convert(enum_value) || enum_value
      end

      # The size (octets) of the `element` field, if present.
      def element_size
        field_offset = @view.unpack_virtual_offset(14)
        return 0 if field_offset.zero?

        @view.unpack_uint(field_offset)
      end

      def fixed_length
        field_offset = @view.unpack_virtual_offset(10)
        return 0 if field_offset.zero?

        @view.unpack_ushort(field_offset)
      end

      def index
        field_offset = @view.unpack_virtual_offset(8)
        return -1 if field_offset.zero?

        @view.unpack_int(field_offset)
      end
    end
  end
end
