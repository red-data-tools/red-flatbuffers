# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"

module FlatBuffers
  module Reflection
    class KeyValue < ::FlatBuffers::Table
      def key
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      def value
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end
    end
  end
end
