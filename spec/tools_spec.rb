# coding: utf-8
require 'spec_helper'
require 'argparser/tools'

class StubClass
  include ArgParser::Tools
  attr_reader :hash
  attr_reader :array
  attr_reader :value
end

describe 'hash behaviour' do
  before do
    @hash = { :array => [StubClass.new, StubClass.new],
              :hash  => {'foo' => 1, 'bar' => 2},
              :value => 'foo' }
  end

  it 'allows to pack/unpack' do
    obj1 = StubClass.new.hash2vars!(@hash)
    hash = obj1.to_hash
    obj2 = StubClass.new.hash2vars!(hash)
    obj1.hash.each{|k, v| obj2.hash[k].must_equal(v)}
    obj1.array.must_equal(obj2.array)
    obj1.value.must_equal(obj2.value)
    obj1.wont_be_same_as(obj2)
  end
end
