# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"
require_relative "key_value"
require_relative "type"

module FlatBuffers
  module Reflection
    class Field < ::FlatBuffers::Table
      def attributes
        field_offset = @view.unpack_virtual_offset(22)
        return nil if field_offset.zero?

        element_size = 4
        @view.unpack_vector(field_offset, element_size) do |element_offset|
          @view.unpack_table(KeyValue, element_offset)
        end
      end

      def default_integer
        field_offset = @view.unpack_virtual_offset(12)
        return 0 if field_offset.zero?

        @view.unpack_long(field_offset)
      end

      def default_real
        field_offset = @view.unpack_virtual_offset(14)
        return 0.0 if field_offset.zero?

        @view.unpack_double(field_offset)
      end

      def deprecated?
        field_offset = @view.unpack_virtual_offset(16)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def documentation
        field_offset = @view.unpack_virtual_offset(24)
        return nil if field_offset.zero?

        element_size = 4
        @view.unpack_vector(field_offset, element_size) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end

      def id
        field_offset = @view.unpack_virtual_offset(8)
        return 0 if field_offset.zero?

        @view.unpack_ushort(field_offset)
      end

      def key?
        field_offset = @view.unpack_virtual_offset(20)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def name
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def offset
        field_offset = @view.unpack_virtual_offset(10)
        return 0 if field_offset.zero?

        @view.unpack_ushort(field_offset)
      end

      # If the field uses 64-bit offsets.
      def offset64?
        field_offset = @view.unpack_virtual_offset(30)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def optional?
        field_offset = @view.unpack_virtual_offset(26)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      # Number of padding octets to always add after this field. Structs only.
      def padding
        field_offset = @view.unpack_virtual_offset(28)
        return 0 if field_offset.zero?

        @view.unpack_ushort(field_offset)
      end

      def required?
        field_offset = @view.unpack_virtual_offset(18)
        return false if field_offset.zero?

        @view.unpack_bool(field_offset)
      end

      def type
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        @view.unpack_table(Type, field_offset)
      end
    end
  end
end
