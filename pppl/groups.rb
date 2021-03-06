require 'irb/completion'
require 'dspace'

DSpace.load


hdl = '88435/dsp01pz50gz45g'
def rec_members(group)
  gmems = group.getMemberGroups
  mems = gmems.collect{|g| g} + group.getMembers.collect {|m| m}
  for g in gmems do
    mems += rec_members(g)
  end
  return mems
end

def doit(hdl)
  root = DSpace.fromString(hdl)
  colls = root.getAllCollections()
  puts "-- SUBMITTERS"
  for c in colls do
    submitters =  DSpace.create(c.getSubmitters).members()
    mems = rec_members(submitters[0]) << submitters[0]
    puts ([c.getName, 'SUBMITTERS', mems.collect{|s| s.getName }.sort].join("\t"))
  end
  for stp in [1,2,3] do
      puts ""
      puts "-- STEP #{stp}"
      for c in colls do
      group =  c.getWorkflowGroup(stp)
      if (group) then
        mems = rec_members(group)
        puts ([c.getName, "STEP #{stp}", mems.collect{|s| s.getName }.sort].join("\t"))
      end
    end
  end
end

doit(hdl)