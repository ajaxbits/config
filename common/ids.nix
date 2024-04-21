{
  config,
  lib,
  ...
}: let
  inherit (lib) any attrNames filter hasAttr length mapAttrsToList mkMerge unique;

  /*
    *
  Outputs duplicates in a list.

  Given a list, returns a list of elements that appear more than once.

  # Examples

  ```
  getDuplicates [ "foo", "bar", "foo" ]
  ->
  [ "foo" ]
  ``

  # Type

  ```
  getDuplicates :: [a] -> [a]
  ```

  # Arguments

  - [list] List of elements to find duplicates within.

  */
  getDuplicates = list: let
    countOccurrences = elem: length (filter (x: x == elem) list);
    duplicates = filter (elem: countOccurrences elem > 1) list;
  in
    unique duplicates;

  conflictingUsersAndGroups = let
    inherit (config.ids) gids uids;
  in
    filter (userName: hasAttr userName gids && uids.${userName} == gids.${userName}) (attrNames uids);

  allUids = mapAttrsToList (_user: id: id) config.ids.uids;
  allGids = mapAttrsToList (_group: id: id) config.ids.gids;

  duplicateUids = getDuplicates allUids;
  duplicateGids = getDuplicates allGids;
in {
  assertions = [
    {
      assertion = duplicateUids == [];
      message = "Duplicate UIDs found in ids.uids: ${lib.concatStringsSep ", " (lib.map toString duplicateUids)}";
    }
    {
      assertion = duplicateGids == [];
      message = "Duplicate UIDs found in ids.gids: ${lib.concatStringsSep ", " (lib.map toString duplicateGids)}";
    }
    {
      assertion = conflictingUsersAndGroups == [];
      message = ''
        The following users were found that have the same id as a group of the same name.
          ${lib.concatStringsSep ", " conflictingUsersAndGroups}
        Change the group or user id number to be distinct.'';
    }
  ];
  config.ids = mkMerge [
    config.ids
    {
      uids = {
        audiobookshelf = 986;
      };
      gids = {
        audiobookshelf = 983;
        mediaoperators = 986;
        configoperators = 982;
      };
    }
  ];
}
