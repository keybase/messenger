
--- 
---  We also need uid <-> username mappings, and also uid <-> key mappings,
---    but we do that via API access to the main keybase.
--- 

-- Incoming notifications get queued here.  Writes to this table aren't authenticated,
-- but might be controlled via postage stamps of some sort.
CREATE TABLE `notifications` (
	`uid` CHAR(32) NOT NULL,
	`notifcation_zid` UNSIGNED INTEGER(11) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`data`  MEDIUMTEXT NOT NULL,
	PRIMARY KEY(`uid`, `notification_zid`),
	INDEX(`uid`, `ctime`),
	INDEX(`uid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- Postage bundles for users to affix to their outgoing mails
CREATE TABLE `outgoing_postage` (
	`uid` CHAR(32) NOT NULL,
	`op_zid` INTEGER UNSIGNED(11) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`mtime` UNSIGNED BIGINT NOT NULL,
	`edata` MEDIUMTEXT NOT NULL,
	PRIMARY KEY(`uid`, `op_zid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `incoming_postage` (
	`uid` CHAR(32) NOT NULL,
	`stamp_id` CHAR(32) NOT NULL,
	`itime` UNSIGNED BIGINT NOT NULL, -- when it was issued
	`stime` UNSIGNED BIGINT NOT NULL, -- when it was spent
	`status` UNSIGNED INT(11) NOT NULL, -- its spend status
	PRIMARY KEY(`uid`, `stamp_id`)
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
