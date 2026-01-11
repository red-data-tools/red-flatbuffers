# Copyright 2026 Sutou Kouhei <kou@clear-code.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "append_as_bytes"

module FlatBuffers
  using AppendAsBytes if const_defined?(:AppendAsBytes)

  module Alignable
    LARGEST_ALIGNMENT_SIZE = 8 # IO::Buffer.size_of(:u64)
    LARGEST_PADDING = "\x00" * 7

    private
    def compute_padding_size(size, alignment_byte)
      (alignment_byte - (size & (alignment_byte - 1))) & (alignment_byte - 1)
    end

    def padding(padding_size)
      LARGEST_PADDING[0, padding_size]
    end

    def pad!(data, padding_size)
      return if padding_size.zero?
      data.append_as_bytes(padding(padding_size))
    end

    def align!(data, alignment_byte)
      pad!(data, compute_padding_size(data.bytesize, alignment_byte))
    end
  end
end
