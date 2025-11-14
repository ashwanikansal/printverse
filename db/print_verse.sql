CREATE DATABASE IF NOT EXISTS `print_verse`;
USE `print_verse`;

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------
-- Table structure for table `artworks`
-- ------------------------------------------------------
DROP TABLE IF EXISTS `artworks`;

CREATE TABLE `artworks` (
  `art_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `anime` VARCHAR(255) DEFAULT NULL,
  `price` DECIMAL(10,2) DEFAULT NULL,
  PRIMARY KEY (`art_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert sample artworks
LOCK TABLES `artworks` WRITE;

INSERT INTO `artworks` (`art_id`,`name`,`anime`,`price`) VALUES
 (1,'Sukuna Hollow Purple','Jujutsu Kaisen',399.00),
 (2,'Luffy Gear 5','One Piece',399.00),
 (3,'Tanjiro Water Breathing','Demon Slayer',399.00),
 (4,'Itachi Moon Stare','Naruto',399.00),
 (5,'Roronoa Zoro Sword','One Piece',399.00),
 (6,'Saitama Minimal Punch','One Punch Man',399.00);

UNLOCK TABLES;

-- ------------------------------------------------------
-- Table structure for table `orders`
-- ------------------------------------------------------
DROP TABLE IF EXISTS `orders`;

CREATE TABLE `orders` (
  `order_id` INT NOT NULL,
  `art_id` INT NOT NULL,
  `quantity` INT DEFAULT 1,
  `price_each` DECIMAL(10,2) DEFAULT NULL,
  `total_price` DECIMAL(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`art_id`),
  KEY `idx_art_id` (`art_id`),
  CONSTRAINT `order_items_fk_art` FOREIGN KEY (`art_id`) REFERENCES `artworks` (`art_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Insert sample order items
LOCK TABLES `orders` WRITE;

INSERT INTO `orders` (`order_id`,`art_id`,`quantity`,`price_each`,`total_price`) VALUES
 (1001,1,2,399.00,798.00),  -- Sukuna x2
 (1001,2,1,399.00,399.00),  -- Luffy x1
 (1002,3,2,399.00,798.00);  -- Tanjiro x2

UNLOCK TABLES;

-- ------------------------------------------------------
-- Table structure for table `order_tracking`
-- ------------------------------------------------------
DROP TABLE IF EXISTS `order_tracking`;

CREATE TABLE `order_tracking` (
  `order_id` INT NOT NULL,
  `status` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Insert sample tracking statuses
LOCK TABLES `order_tracking` WRITE;

INSERT INTO `order_tracking` (`order_id`,`status`) VALUES
 (1001,'Delivered'),
 (1002,'In Transit');

UNLOCK TABLES;

-- ------------------------------------------------------
-- Functions and Procedures
-- ------------------------------------------------------
DROP FUNCTION IF EXISTS get_price_for_artwork;


DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `get_price_for_artwork`(p_art_name VARCHAR(255)) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_price DECIMAL(10,2);
    IF (SELECT COUNT(*) FROM artworks WHERE name = p_art_name) > 0 THEN
        SELECT price INTO v_price 
        FROM artworks 
        WHERE name = p_art_name LIMIT 1;
        RETURN v_price;
    ELSE
        RETURN -1;
    END IF;
END ;;
DELIMITER ;

DROP FUNCTION IF EXISTS get_total_order_price;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `get_total_order_price`(p_order_id INT) RETURNS decimal(10,2)
    DETERMINISTIC
BEGIN
    DECLARE v_total_price DECIMAL(10,2);
    IF (SELECT COUNT(*) FROM orders WHERE order_id = p_order_id) > 0 THEN
        SELECT SUM(total_price) INTO v_total_price 
        FROM orders 
        WHERE order_id = p_order_id;
        RETURN IFNULL(v_total_price, 0.00);
    ELSE
        RETURN -1;
    END IF;
END ;;
DELIMITER ;

DROP PROCEDURE IF EXISTS insert_order_item;

DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_order_item`(
  IN p_art_name VARCHAR(255),
  IN p_quantity INT,
  IN p_order_id INT
)
BEGIN
    DECLARE v_art_id INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_total_price DECIMAL(10,2);

    -- Get the art id and price for the artwork
    SET v_art_id = (SELECT art_id FROM artworks WHERE name = p_art_name LIMIT 1);
    SET v_price = (SELECT get_price_for_artwork(p_art_name));

    IF v_art_id IS NULL OR v_price < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid artwork name';
    END IF;

    -- Calculate total price
    SET v_total_price = v_price * p_quantity;

    -- Insert or update: if same art already exists in order, update quantity & totals
    IF EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id AND art_id = v_art_id) THEN
        UPDATE orders
        SET quantity = quantity + p_quantity,
            total_price = total_price + v_total_price
        WHERE order_id = p_order_id AND art_id = v_art_id;
    ELSE
        INSERT INTO orders (order_id, art_id, quantity, price_each, total_price)
        VALUES (p_order_id, v_art_id, p_quantity, v_price, v_total_price);
    END IF;

END ;;
DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;