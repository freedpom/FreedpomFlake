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

      inherit (builtins) typeOf replaceStrings elem;

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
        name: attrs: firstArg:
        let
          arg =
            if firstArg != null then
              literalValueToString firstArg
            else if attrs.name != null then
              literalValueToString attrs.name
            else
              null;

          # remove keys that are special or already used
          childAttrs = builtins.removeAttrs attrs [
            "name"
            "_args"
            "_props"
            "_children"
          ];

          # convert any _children first
          orderedChildren = flatten (
            map (child: mapAttrsToList convertAttributeToKDL child) (attrs._children or [ ])
          );

          # convert remaining attributes
          unorderedChildren = mapAttrsToList convertAttributeToKDL childAttrs;

          children = orderedChildren ++ unorderedChildren;

          optChildren = optional (children != [ ]) ''
            {
            ${indentStrings children}
            } '';
        in
        concatStringsSep " " ([ name ] ++ (if arg != null then [ arg ] else [ ]) ++ [ optChildren ]);

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
          # Treat key as name, value as children if it's a set
          convertAttrsToKDL name value
        else if t == "list" then
          convertListToKDL name value
        else
          throw "Cannot convert type `${t}` to KDL: ${name} = ${toString value}";

    in
    attrs: concatStringsSep "\n" (mapAttrsToList convertAttributeToKDL attrs);

}
