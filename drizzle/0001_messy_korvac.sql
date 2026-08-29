CREATE TABLE `consultationRequests` (
	`id` int AUTO_INCREMENT NOT NULL,
	`reference` varchar(24) NOT NULL,
	`fullName` varchar(160) NOT NULL,
	`email` varchar(320),
	`phone` varchar(40),
	`preferredDate` varchar(32),
	`preferredTimes` text,
	`notes` text,
	`language` varchar(8) NOT NULL DEFAULT 'en',
	`status` enum('new','contacted','closed') NOT NULL DEFAULT 'new',
	`createdAt` timestamp NOT NULL DEFAULT (now()),
	`updatedAt` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `consultationRequests_id` PRIMARY KEY(`id`),
	CONSTRAINT `consultationRequests_reference_unique` UNIQUE(`reference`)
);
