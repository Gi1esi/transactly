-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `mydb` ;

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

-- -----------------------------------------------------
-- Table `mydb`.`users`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`users` (
  `user_id` INT NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(45) NOT NULL,
  `last_name` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE INDEX `idusers_UNIQUE` (`user_id` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`banks`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`banks` (
  `bank_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `sms_address_box` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`bank_id`),
  UNIQUE INDEX `bank_id_UNIQUE` (`bank_id` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`accounts`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`accounts` (
  `account_id` INT NOT NULL AUTO_INCREMENT,
  `account_number` VARCHAR(45) NOT NULL,
  `bank` INT NULL,
  `user` INT NULL,
  PRIMARY KEY (`account_id`),
  UNIQUE INDEX `account_id_UNIQUE` (`account_id` ASC) VISIBLE,
  INDEX `account_bank_idx` (`bank` ASC) VISIBLE,
  INDEX `account_user_idx` (`user` ASC) VISIBLE,
  CONSTRAINT `account_bank`
    FOREIGN KEY (`bank`)
    REFERENCES `mydb`.`banks` (`bank_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `account_user`
    FOREIGN KEY (`user`)
    REFERENCES `mydb`.`users` (`user_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`categories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`categories` (
  `category_id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `type` ENUM('income', 'expense') NOT NULL,
  `icon_key` VARCHAR(45) NOT NULL,
  `color_hex` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE INDEX `category_id_UNIQUE` (`category_id` ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `mydb`.`transactions`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `mydb`.`transactions` (
  `transaction_id` BIGINT(10) NOT NULL AUTO_INCREMENT,
  `trans_id` VARCHAR(45) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `amount` INT NOT NULL,
  `date` DATE NOT NULL,
  `effect` ENUM('cr', 'dr') NOT NULL,
  `category` INT NULL,
  `account` INT NULL,
  PRIMARY KEY (`transaction_id`),
  UNIQUE INDEX `transaction_id_UNIQUE` (`transaction_id` ASC) VISIBLE,
  INDEX `transaction_category_idx` (`category` ASC) VISIBLE,
  INDEX `transaction_account_idx` (`account` ASC) VISIBLE,
  INDEX `transaction_date` (`date` ASC) VISIBLE,
  CONSTRAINT `transaction_category`
    FOREIGN KEY (`category`)
    REFERENCES `mydb`.`categories` (`category_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `transaction_account`
    FOREIGN KEY (`account`)
    REFERENCES `mydb`.`accounts` (`account_id`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
