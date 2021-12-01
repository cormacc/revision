require 'spec_helper'

RSpec.describe Revision do
  it "has a version number" do
    expect(Revision::VERSION).not_to be nil
  end
end
