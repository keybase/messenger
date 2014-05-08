
--- 
---  We also need uid <-> username mappings, and also uid <-> key mappings,
---    but we do that via API access to the main keybase.
--- 

-- Incoming notifications get queued here.
-- Writes to this table have to be authenticated with a valid token for the user.
CREATE TABLE `notifications` (
	`notification_id` CHAR(64) NOT NULL PRIMARY KEY,
	`uid` CHAR(32) NOT NULL,
	`thread_id` CHAR(64) NOT NULL,
	`notification_zid` UNSIGNED INTEGER(11) NOT NULL,
	`token_id` CHAR(32) NOT NULL,           -- the token associated with the notification.
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`data`  MEDIUMTEXT NOT NULL,
	INDEX(`uid`, `thread_id`),
	INDEX(`uid`, `ctime`),
	INDEX(`uid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Users can generate tokens offline, so long as they are signed with the
-- private keys that correspond to these public keys.
CREATE TABLE `token_generation_keys` (
	`uid` CHAR(32) NOT NULL,
	`fingerprint` CHAR(40) NOT NULL,
	`key_data` TEXT,
	PRIMARY KEY(`uid`, `fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Weak password that can be exchanged for tokens.
CREATE TABLE `passwords` (
	`uid` CHAR(32) NOT NULL,
	`password` VARCHAR(128) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`etime` UNSIGNED BIGINT NOT NULL, -- when it was revoked (or 0 if not)
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY(`uid`, `password`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tokens that are authorized for incoming conversations.
CREATE TABLE `in_tokens` (
	`uid` CHAR(32) NOT NULL,
	`token_id` CHAR(32) NOT NULL,            -- the ID of the token to see which one
	`token_value` VARCHAR(64) NOT NULL,      -- base64-encoded, use as an HMAC key
	`ctime` UNSIGNED BIGINT NOT NULL,        -- when it was created
	`etime` UNSIGNED BIGINT NOT NULL,        -- when it expires if not pre-expired
	`status` UNSIGNED INT(11) NOT NULL,      
	`source_type` UNSIGNED INT(11) NOT NULL, -- can be { 1=PW, 2=BitCoin, 3=KeyGenerated }
	`source_id` VARCHAR(256) NOT NULL,       -- the address to be blackholed if there's a problem
	`comment` TEXT,                          -- comment on why revoked?
	PRIMARY KEY(`uid`, `token_id`),
	KEY (`source_type`, `source_id`)         -- for revocation lookups
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `bitcoin_blacklist` (
	`uid` CHAR(32) NOT NULL,
	`address` VARCHAR(64) NOT NULL,
	`token_id` CHAR(32) NOT NULL,            -- which token was revoked in concert
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`comment` TEXT,
	PRIMARY KEY(`uid`, `address`),
	KEY(`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Threads can be written back the server in "compacted form" and encrypted
-- for the user who owns it.  Writes to this table should be authenticated.
CREATE TABLE `threads` (
	`uid` CHAR(32) NOT NULL,
	`thread_id` CHAR(32) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`mtime` UNSIGNED BIGINT NOT NULL,
	`edata` MEDIUMTEXT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY (`uid`, `thread_id`),
	INDEX (`uid`, `mtime`),
	INDEX (`uid`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Tokens that users on this server can use to make outgoing requests.
-- They are encrypted with the user's public key.
CREATE TABLE `out_tokens` (
	`uid` CHAR(32) NOT NULL,
	`out_token_zid` UNSIGNED INT(11) NOT NULL,  -- sequential ID
	`ctime` UNSIGNED BIGINT NOT NULL,
	`mtime` UNSIGNED BIGINT NOT NULL,
	`edata` MEDIUMTEXT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY(`uid`, `out_token_zid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
