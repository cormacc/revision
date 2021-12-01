require 'spec_helper'

module Revision
  RSpec.describe MD5 do
    it "should read in 1024KB chunks" do
      expect(MD5::READ_CHUNK_KB).to eq 1024
    end

    it "should produce expected md5sum given string reader" do
      #Given
      md5 = MD5.new(StringIO.new("abc\n"), "bla.bla")

      #When/then
      expect(md5.calc).to eq "0bee89b07a248e27c83fc3d5951213c1"
    end
  end
end
