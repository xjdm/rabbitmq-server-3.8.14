def is_unique(l):
  return len(l) == len(set(l))
end

def merge(dicts):
  r = {}
  for d in dicts:
    r.update(**d)
  end
  return r
end

def name(suites):
  if len(suites) == 1:
    return suites[0].name
  else:
    return suites[0].name + "-plus-" + str(len(suites) - 1) + "-more"
  end
end

def sum(ints):
  s = 0
  for i in ints:
    s += i
  end
  return s
end

def partition(target, groups, suites):
  if len(suites) == 0:
    return groups
  end
  group = []
  rest = []
  for suite in sorted(suites, key=lambda suite: suite.time):
    if sum([suite2.time for suite2 in group]) + suite.time <= target:
      group.append(suite)
    else:
      rest.append(suite)
    end
  end
  return partition(target, groups + [group], rest)
end

def to_build_args(d):
  return ",".join(['{0}={1}'.format(k,d[k]) for k in d.keys()])
end
