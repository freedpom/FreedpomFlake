{ lib }:
{
  toKDL =
    _:
    let
      inherit (lib)
        concatStringsSep
        mapAttrsToList
        any
        pipe
        flatten
        splitString
        filterAttrs
        optional
        throwIfNot
        ;
      inherit (builtins)
        typeOf
        replaceStrings
        elem
        ;
      indentStrings =
        strings:
        let
          lines = splitString "\n" (concatStringsSep "\n" strings);
        in
        concatStringsSep "\n" (map (l: "\t" + l) lines);
      sanitizeString = replaceStrings [ "\\" "\n" ''"'' ] [ "\\\\" "\\n" ''\"'' ];
      literalValueToString =
        value:
        let
          t = typeOf value;
        in
        throwIfNot
          (elem t [
            "int"
            "float"
            "string"
            "bool"
            "null"
          ])
          "Cannot convert value of type ${t} to KDL literal. Got: ${toString value}"
          (
            if t == "null" then
              "null"
            else if t == "bool" then
              if value then "true" else "false"
            else if t == "string" then
              ''"${sanitizeString value}"''
            else
              toString value
          );
      convertAttrsToKDL =
        name: attrs:
        let
          # Extract _args first, or use 'name' attribute if present
          explicitArgs = attrs._args or [ ];
          nameArg = optional (attrs ? name && explicitArgs == [ ]) attrs.name;
          optArgs = map literalValueToString (explicitArgs ++ nameArg);

          # Filter out 'name' from props if it was used as an arg
          attrsWithoutName =
            if (attrs ? name && explicitArgs == [ ]) then removeAttrs attrs [ "name" ] else attrs;

          optProps = mapAttrsToList (k: v: "${k}=${literalValueToString v}") (attrsWithoutName._props or { });

          orderedChildren = pipe (attrsWithoutName._children or [ ]) [
            (map (child: mapAttrsToList convertAttributeToKDL child))
            flatten
          ];

          # Create children from remaining attributes (excluding special ones and 'name')
          unorderedChildren = pipe attrsWithoutName [
            (filterAttrs (
              k: _:
              !(elem k [
                "_args"
                "_props"
                "_children"
              ])
            ))
            (mapAttrsToList convertAttributeToKDL)
          ];

          children = orderedChildren ++ unorderedChildren;
          optChildren = optional (children != [ ]) ''
            {
            ${indentStrings children}
            }'';
        in
        concatStringsSep " " ([ name ] ++ optArgs ++ optProps ++ optChildren);
      convertListToKDL =
        name: list:
        let
          isFlat =
            v:
            elem (typeOf v) [
              "int"
              "float"
              "bool"
              "null"
              "string"
            ];
          elementsAreFlat = !any (v: !isFlat v) list;
        in
        if elementsAreFlat then
          "${name} ${concatStringsSep " " (map literalValueToString list)}"
        else
          # For non-flat lists, convert each element as a separate node with the parent name
          concatStringsSep "\n" (map (v: convertAttributeToKDL name v) list);

      # Check if an attrset should be "expanded" (each key becomes a separate parent node)
      shouldExpand =
        attrs:
        # Only expand if explicitly requested
        attrs._expand or false;

      convertAttributeToKDL =
        name: value:
        let
          t = typeOf value;
        in
        if
          elem t [
            "int"
            "float"
            "bool"
            "null"
            "string"
          ]
        then
          "${name} ${literalValueToString value}"
        else if t == "set" then
          # Check if this attrset should be expanded
          if shouldExpand value then
            let
              filteredAttrs = filterAttrs (k: _: k != "_expand") value;
            in
            concatStringsSep "\n" (
              mapAttrsToList (
                k: v:
                # Each key becomes a positional arg for a new node with the parent name
                convertAttrsToKDL name (v // { _args = [ k ]; })
              ) filteredAttrs
            )
          else
            convertAttrsToKDL name value
        else if t == "list" then
          convertListToKDL name value
        else
          throw "Cannot convert type `${t}` to KDL for attribute '${name}'. Value: ${toString value}";
      convertTop =
        value:
        let
          t = typeOf value;
        in
        if t == "set" then
          mapAttrsToList convertAttributeToKDL value
        else if t == "list" then
          map convertTop value # recurse for nested lists if needed
        else
          throw "Top-level must be attrset or list, got ${t}. Cannot convert: ${toString value}";
    in
    top: concatStringsSep "\n\n" (flatten (convertTop top));
}
