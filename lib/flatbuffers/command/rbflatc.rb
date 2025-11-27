# Copyright 2025 Sutou Kouhei <kou@clear-code.com>
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

require "optparse"
require "pathname"

require "flatbuffers"
require "flatbuffers/generator"

module FlatBuffers
  module Command
    class RBFlatc
      def initialize
        @output_dir = Pathname(".")
        @outer_namespaces = nil
      end

      def run(argv)
        path, = parse_options(argv)
        File.open(path, "rb") do |input|
          buffer = IO::Buffer.map(input, nil, 0, IO::Buffer::READONLY)
          generator = FlatBuffers::Generator.new(buffer)
          generator.output_dir = @output_dir
          generator.outer_namespaces = @outer_namespaces
          generator.generate
        end
        true
      end

      private
      def parse_options(argv)
        parser = OptionParser.new
        parser.banner += " BFBS_PATH"
        parser.version = FlatBuffers::VERSION
        parser.on("--output-dir=DIR",
                  "Output to DIR",
                  "(#{@output_dir})") do |dir|
          @output_dir = Pathname(dir)
        end
        parser.on("--outer-namespaces=NAMESPACES",
                  "Wrap all codes by NAMESPACES",
                  "e.g.: My::Namespace") do |namespaces|
          @outer_namespaces = namespaces.split("::").compact
        end
        parser.parse!(argv)
      end
    end
  end
end
