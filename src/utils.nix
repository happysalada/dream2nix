{
  lib,
  ...
}:
rec {
  basename = path: lib.last (lib.splitString "/" path);

  dirname = path: builtins.concatStringsSep "/" (lib.init (lib.splitString "/" path));

  isFile = path: (builtins.readDir (dirname path))."${basename path}" ==  "regular";

  isDir = path: (builtins.readDir (dirname path))."${basename path}" ==  "directory";

  listFiles = path: lib.filterAttrs (n: v: v == "regular") (builtins.listDir path);

  matchTopLevelFiles = pattern: path:
    # is dir
    if isDir path then
      builtins.all (f: matchTopLevelFiles pattern f) (listFiles path)
    
    # is file
    else
      let
        match = (builtins.match pattern path);
      in
        if match == null then false else builtins.any (m: m != null) match;
  
  compatibleTopLevelPaths = pattern: paths:
    lib.filter
      (path:
        matchTopLevelFiles
          pattern
          path
      )
      paths;

  # allow a function to receive its input from an environment variable
  # whenever an empty set is passed
  makeCallableViaEnv = func: args:
    if args == {} then
      func (builtins.fromJSON (builtins.readFile (builtins.getEnv "FUNC_ARGS")))
    else
      func args;

  removeCycles = dreamLock:
    let
      graph = dreamLock.generic.dependencyGraph;

      nodesList =
        lib.mapAttrsToList
          (name: deps: { inherit name deps; })
          graph;
      
      # this doesn't work since it doesn't detect transitive dependencies
      # TODO: fix this
      dependsOn = node1: node2:
        builtins.elem node2.name graph."${node1.name}";

    in
    lib.recursiveUpdate dreamLock {
      generic.dependencyGraph =
        lib.listToAttrs
          (map
            (node: lib.nameValuePair node.name node.deps)
            (removeCyclesInternal dependsOn nodesList)
          );
    };

  removeCyclesInternal = dependsOn: nodesList:
    let
      result = lib.toposort dependsOn nodesList;
    in
      if result ? result then
        builtins.trace (lib.attrNames result)
        result.result
      else
        let
          nodeToRemove = lib.last result.cycle;
          nodeFrom = lib.elemAt result.cycle ((builtins.length result.cycle) - 2);
        in
          builtins.trace "Removing cyclic dependency: ${nodeFrom.name} -> ${nodeToRemove.name}"
          removeCyclesInternal
            dependsOn
            (lib.filter (node: node.name != nodeToRemove.name) nodesList);

}
