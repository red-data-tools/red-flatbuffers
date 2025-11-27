# Automatically generated. Don't modify manually.
#
# Red FlatBuffers version: 0.0.1
# Declared by:             //reflection.fbs
# Rooting type:            reflection.Schema (//reflection.fbs)

require "flatbuffers"

module FlatBuffers
  module Reflection
    # File specific information.
    # Symbols declared within a file may be recovered by iterating over all
    # symbols and examining the `declaration_file` field.
    class SchemaFile < ::FlatBuffers::Table
      # Filename, relative to project root.
      def filename
        field_offset = @view.unpack_virtual_offset(4)
        return nil if field_offset.zero?

        @view.unpack_string(field_offset)
      end

      # Names of included files, relative to project root.
      def included_filenames
        field_offset = @view.unpack_virtual_offset(6)
        return nil if field_offset.zero?

        @view.unpack_vector(field_offset, 4) do |element_offset|
          @view.unpack_string(element_offset)
        end
      end
    end
  end
end
