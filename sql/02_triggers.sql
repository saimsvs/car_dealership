
-- A CHECK only sees the row being written - no clock, no other
-- rows. These rules need CURRENT_DATE or another table, so they
-- are implemented as triggers.
-- ============================================================


-- ------------------------------------------------------------
-- Rule 2: a valid CNIC is required; an expired one is refused.
-- Applies to the seller and the buyer (customer).
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_cnic_expiry() RETURNS trigger AS $$
BEGIN
    IF NEW.cnic_expiry < CURRENT_DATE THEN
        RAISE EXCEPTION 'CNIC % expired on % - expired CNIC refused',
            NEW.cnic, NEW.cnic_expiry;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cnic_customer ON customer;
CREATE TRIGGER trg_cnic_customer
    BEFORE INSERT OR UPDATE ON customer
    FOR EACH ROW EXECUTE FUNCTION check_cnic_expiry();

DROP TRIGGER IF EXISTS trg_cnic_seller ON seller;
CREATE TRIGGER trg_cnic_seller
    BEFORE INSERT OR UPDATE ON seller
    FOR EACH ROW EXECUTE FUNCTION check_cnic_expiry();


-- ------------------------------------------------------------
-- Rule 9 (+ rule 8): every sold car must be transferred within
-- 7 days, so transfer_due_date defaults to sale_date + 7.
-- Rule 8 lets repeat customers be given more time, so an
-- explicitly supplied due date is left untouched.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_transfer_due() RETURNS trigger AS $$
BEGIN
    IF NEW.transfer_due_date IS NULL THEN
        NEW.transfer_due_date := NEW.sale_date + 7;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_transfer_due ON sale;
CREATE TRIGGER trg_transfer_due
    BEFORE INSERT ON sale
    FOR EACH ROW EXECUTE FUNCTION set_transfer_due();


-- ------------------------------------------------------------
-- Rule 12: the showroom may buy back a car it sold earlier,
-- from the same customer, only within 2 months of that sale.
-- "Not been in an accident or badly damaged" has no column in
-- the model, so that part stays a staff judgement - documented,
-- not enforced.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_buyback() RETURNS trigger AS $$
DECLARE
    prev_sale   record;
    seller_cnic varchar(50);
BEGIN
    -- most recent completed sale of this car, if one exists
    SELECT s.sale_date, c.cnic AS customer_cnic
      INTO prev_sale
      FROM sale s
      JOIN customer c ON c.customer_id = s.cust_id
     WHERE s.car_id = NEW.car_id
       AND s.sale_status = 'completed'
     ORDER BY s.sale_date DESC
     LIMIT 1;

    -- no previous sale: this is the car's first purchase
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    IF NEW.purchase_date > prev_sale.sale_date + INTERVAL '2 months' THEN
        RAISE EXCEPTION 'buy-back refused: sale was on %, more than 2 months before %',
            prev_sale.sale_date, NEW.purchase_date;
    END IF;

    SELECT cnic INTO seller_cnic FROM seller WHERE seller_id = NEW.seller_id;
    IF seller_cnic IS DISTINCT FROM prev_sale.customer_cnic THEN
        RAISE EXCEPTION 'buy-back refused: car must be bought back from the same customer';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_buyback ON purchase;
CREATE TRIGGER trg_buyback
    BEFORE INSERT ON purchase
    FOR EACH ROW EXECUTE FUNCTION check_buyback();


-- ------------------------------------------------------------
-- Rule 1/6 (optional, not stated in the doc's schema section):
-- a cheque or pay order is untraceable without its number.
-- Cash may or may not have a bank slip, so it stays optional.
-- ------------------------------------------------------------
ALTER TABLE financial_transaction
    DROP CONSTRAINT IF EXISTS ref_required_for_instrument;

ALTER TABLE financial_transaction
    ADD CONSTRAINT ref_required_for_instrument
    CHECK (payment_mode = 'cash' OR reference_no IS NOT NULL);
