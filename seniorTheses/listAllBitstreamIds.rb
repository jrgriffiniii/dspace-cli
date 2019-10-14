#!/usr/bin/env jruby -I ../dspace-jruby/lib 
require 'dspace'

DSpace.load

def all_bitstream_ids(groups )
  # loop over all bitstreams that have at least oneof the given group policies
  n = 0
  groups.each do |group_name|
    bits = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
    puts(group_name + " %s" % bits.length, bits.collect { |b| b.getID } )
  end
end

if true then
  all_bitstream_ids( ["SrTheses_Bitstream_Read_Mudd", "SrTheses_Bitstream_Read_Princeton"   ])
end
