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
          "Cannot convert value of type ${t} to KDL literal."
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
          optArgs = map literalValueToString (attrs._args or [ ]);
          optProps = mapAttrsToList (k: v: "${k}=${literalValueToString v}") (attrs._props or { });
          orderedChildren = pipe (attrs._children or [ ]) [
            (map (child: mapAttrsToList convertAttributeToKDL child))
            flatten
          ];
          unorderedChildren = pipe attrs [
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
          ''
            ${name} {
            ${indentStrings (map (v: convertAttributeToKDL "-" v) list)}
            }'';

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
          convertAttrsToKDL name value
        else if t == "list" then
          convertListToKDL name value
        else
          throw "Cannot convert type `${t}` to KDL: ${name} = ${toString value}";

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
          throw "Top-level must be attrset or list, got ${t}";
    in
    top: concatStringsSep "\n" (flatten (convertTop top));
}
