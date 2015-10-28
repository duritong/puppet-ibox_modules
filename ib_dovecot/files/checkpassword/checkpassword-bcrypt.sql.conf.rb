#!/bin/env ruby

module CheckpasswordBCrypt
  module Config
    module SQL
      # %s will be replaced by the username
      #
      # this query should return (in this order):
      # username,hash,salt,iterations,uid,quota,lastlogin
      UserQuery = <<-eos
SELECT
  #{DB::Field::Username} AS name,
  #{DB::Field::Password} AS hash,
  #{DB::Field::Uid} AS uid,
  #{DB::Field::Quota} AS quota,
  #{DB::Field::Lastlogin} AS lastlogin,
  #{DB::Field::AuthFailures} AS auth_failures,
  #{DB::Field::LockedUntil} AS locked,
  #{DB::Field::InboxNamespacePrefix} AS "namespace/inbox/prefix"
FROM
  #{DB::Table}
WHERE
  #{DB::Field::Username}  = lower('%s') AND
  ismailbox               = '1'         AND
  deleted_at              IS NULL       AND
  migrate_to              IS NULL       AND
  storagehost             = '#{Mail::Storage}'
LIMIT 1
eos

      # %s will be replaced (in this order) by:  hash, username
      #
      # this query should update the user record with the new hash
      UserMigrate = <<-eos
UPDATE
  #{DB::Table}
SET
  #{DB::Field::Password}   ='{BCrypt}%s'
WHERE
  #{DB::Field::Username}  = lower('%s') AND
  ismailbox               = '1'         AND
  deleted_at              IS NULL       AND
  migrate_to              IS NULL       AND
  storagehost             = '#{Mail::Storage}'
eos

      #this query should update the last login field (if enabled).
      # %s will be replaced by lastlogin, username
      UpdateLastLogin = <<-eos
UPDATE
  #{DB::Table}
SET
  #{DB::Field::Lastlogin} = '%s'
WHERE
  #{DB::Field::Username}  = lower('%s') AND
  ismailbox               = '1'         AND
  deleted_at              IS NULL       AND
  migrate_to              IS NULL       AND
  storagehost             = '#{Mail::Storage}'
eos

      #this query should update the login failures (if enabled).
      # %s will be replaced by auth_failures, locked_until, username
      UpdateLoginFailure = <<-eos
UPDATE
  #{DB::Table}
SET
  #{DB::Field::AuthFailures}  = '%s',
  #{DB::Field::LockedUntil}   = '%s'
WHERE
  #{DB::Field::Username}  = lower('%s') AND
  ismailbox               = '1'         AND
  deleted_at              IS NULL       AND
  migrate_to              IS NULL       AND
  storagehost             = '#{Mail::Storage}'
eos
    end
  end
end
