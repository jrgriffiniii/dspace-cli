#!/usr/bin/env jruby -I ../dspace-jruby/lib 
require 'xmlsimple'
require 'dspace'

DSpace.load
java_import org.dspace.authorize.AuthorizeManager


#postgres
# fromString = "COMMUNITY.145"

# dataspace
fromString = '88435/dsp019c67wm88m'
com = DSpace.fromString(fromString)



def items_csv(items, fields)
  puts fields.join("\t")
  n = 0;
  for i in items do
    if i.getHandle then
      DSpace.create(i).bitstreams.each do |b|
        h = do_bitstream b, fields
        csv_out(h, fields)
      end
      n = n + 1
      if (n == 10) then
        DSpace.reload
        n = 0
      end
    end
  end
end


def all_bits(fields, groups )
  # loop over all bitstreams that have at least oneof the given group policies
  n = 0
 groups.each do |group_name|
    bits = DSpace.findByGroupPolicy(group_name, DConstants::READ, DConstants::BITSTREAM)
    puts bits.length
    DSpace.reload
    next
    bits.each do |b|
      h = do_bitstream(b, fields)
      csv_out(h, fields)
      n = n + 1
      if (n == 10) then
        DSpace.reload
        n = 0
      end
    end
  end
end

def do_bitstream(b, fields)
  h = {}
  h[$bitstream_id] = b.getID
  return
  h[$fname] = b.getName
  h[$size] = b.getSize()
  h[$size_MB] = (1.0 * h[$size]) / (1024 * 1024)
  h[$policies] = get_policies(b) if fields.include? $policies
  i = b.getParentObject()
  h[$klass] = (nil == i.getMetadata('pu.date.classyear')) ? '' : i.getMetadata('pu.date.classyear')
  h[$item_id] = i.getID
  h[$handle] = i.getHandle
  h[$col] = i.getParentObject.getName
  h[$walk_msg] = (nil == i.getMetadata('dc.rights.accessRights')) ? '' : i.getMetadata('dc.rights.accessRights')
  h[$walk_msg] = h[$walk_msg][0..10]
  h[$walkin] = (nil == i.getMetadata('pu.mudd.walkin')) ? '---' : i.getMetadata('pu.mudd.walkin')
  h[$elift] = (nil == i.getMetadata('pu.embargo.lift')) ? '---- -- --' : i.getMetadata('pu.embargo.lift')
  h[$eterm] = (nil == i.getMetadata('pu.embargo.terms')) ? '---- -- --' : i.getMetadata('pu.embargo.terms')
  return h
end

def get_policies(b)
  java_import org.dspace.storage.rdbms.DatabaseManager
  sql = "SELECT ACTION_ID,EPERSONGROUP_ID,EPERSON_ID FROM RESOURCEPOLICY WHERE  RESOURCE_ID = #{b.getID} AND RESOURCE_TYPE_ID = 0";
  tri = DatabaseManager.queryTable(DSpace.context, "RESOURCEPOLICY", sql)
  pols = []
  while (iter = tri.next()) do
    action = iter.getIntColumn("ACTION_ID")
    person = DEPerson.find iter.getIntColumn("EPERSON_ID")
    group = DGroup.find iter.getIntColumn("EPERSONGROUP_ID")
    group = group.getName if group
    pols << [action, person, group].join(",")
  end
  tri.close()
  return pols
end

def csv_out(h, fields)
  puts fields.collect {|f| h[f]}.join("\t").gsub(/\n/, ' ').gsub(/\r/, ' ')
end


$all_fields = ['bitstream_id', 'item_id', 'handle', 'filesize MB', 'filesize', 'collection', 'filename', 'year',
               'lift', 'term', 'walkin', 'rights_msg', "policies..."]

$size, $size_MB, $item_id, $bitstream_id, $handle, $col,
    $fname, $klass, $elift, $eterm, $walkin, $walk_msg, $policies = $all_fields

if false then
  # all items that in senior thesis - BEHWRE that is a LOT
  #items = DSpace.findByMetadataValue('pu.date.classyear', nil, nil)

  # all items from 2019
  year = 2019
  items = DSpace.findByMetadataValue('pu.date.classyear', year, nil)
  exclude_fields = [$size, $elift]
  prt_fields = $all_fields.select {|v| not exclude_fields.include? v}
  items_csv(items, prt_fields)
end


if true then
  exclude_fields = [$size]
  prt_fields = $all_fields.select {|v| not exclude_fields.include? v}
  prt_fields = [$bitstream_id]
  # taking advantage of fact that senior thesis bitstreams are either protected by
  # SrTheses_Bitstream_Read_Mudd or SrTheses_Item_Read_Anonymous groups
  all_bits(prt_fields,  ["SrTheses_Bitstream_Read_Princeton", "SrTheses_Bitstream_Read_Mudd"  ])
end
