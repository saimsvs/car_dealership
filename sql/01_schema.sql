
-- Drop in reverse dependency order so this file can be re-run cleanly.
-- WARNING: this deletes all rows in these tables.
DROP TABLE IF EXISTS financial_transaction, sale, employee, customer,
                     purchase, seller, maintenance, car CASCADE;

-- ------------------------------------------------------------
-- 4. Car
-- One row per car in the showroom's history.
-- Sections 4.1 / 4.2: no foreign keys - Car is a parent to
-- purchase, maintenance and sale.
-- ------------------------------------------------------------
CREATE TABLE if not EXISTS car (
    car_id       INTEGER       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model        VARCHAR(50)   NOT NULL,
    registration VARCHAR(20)   NOT NULL UNIQUE,
    chassis_no   VARCHAR(30)   NOT NULL UNIQUE,
    engine_no    VARCHAR(30)   NOT NULL UNIQUE,
    colour       VARCHAR(30)   NOT NULL,
    status       VARCHAR(20)   NOT NULL DEFAULT 'in preparation'
                               CHECK (status IN ('in preparation',
                                                 'available',
                                                 'reserved',
                                                 'sold'))
);

CREATE table if not EXISTS maintenance (
repair_id INT  GENERATED ALWAYS AS IDENTITY  primary key,
car_part  varchar(50) not null,
cost NUMERIC(12,2) not null,
owed_to varchar(50) not null,
car_id int not null,
foreign key (car_id) references  car(car_id));

CREATE table if not EXISTS seller(
seller_id int GENERATED ALWAYS as IDENTITY primary key,
name varchar(50) not null,
cnic varchar(15) not null,
cnic_expiry date not null,
address varchar(100) not null,
business_address varchar(100),
seller_type varchar(50) not null check (seller_type in ('customer', 'dealer', 'mechanic'))
);

CREATE table if not EXISTS purchase(
purchase_id int GENERATED ALWAYS AS IDENTITY primary key,
purchase_date  date not null,
buying_price NUMERIC(12,2),
seller_id int not null,
car_id  int not null,
foreign key (seller_id) references  seller(seller_id),
foreign key (car_id) references  car(car_id)

);


CREATE table if not EXISTS customer(

customer_id int GENERATED ALWAYS AS IDENTITY primary key,
name varchar(50) not null,
cnic varchar(50) not null,
cnic_expiry date not null,
address varchar(100) not null,
business_address varchar(50) 

);

CREATE table if not EXISTS employee(
emp_id int GENERATED ALWAYS as IDENTITY primary key,
name varchar(50) not null,
cnic varchar(15) not null,
cnic_expiry date not null,
address varchar(100) not null,
department varchar(50) not null
);

CREATE table if not EXISTS sale(
sale_id int GENERATED ALWAYS as IDENTITY primary key,
selling_price NUMERIC(12,2) not null,
sale_date date not null,
sale_status varchar(10) not null default 'reserved' check (sale_status in ('reserved', 'completed', 'cancelled')),
transfer_due_date date,
transfer_status varchar(20) not null default 'pending' check (transfer_status in ('pending', 'in progress', 'completed')),
cust_id int not null references customer(customer_id),
car_id int not null references car(car_id),
emp_id int not null references employee(emp_id)
);

CREATE table if not EXISTS financial_transaction(
    transaction_id int GENERATED ALWAYS AS IDENTITY primary key,
    dt date not null,
    amount NUMERIC(12,2) not null,
    payment_mode varchar(50) not null check (payment_mode in ('cash','cheque','pay_order')),
    reference_no varchar(30),
    txn_type varchar(20) not null check (txn_type in ('purchase payment','repair payment','sale payment','token','token refund')),
    repair_id  
     INT REFERENCES maintenance(repair_id),  
purchase_id INT REFERENCES purchase(purchase_id),   
sale_id     INT REFERENCES sale(sale_id),   
CONSTRAINT one_parent_only
    CHECK (num_nonnulls(repair_id, purchase_id, sale_id) = 1)       
);
