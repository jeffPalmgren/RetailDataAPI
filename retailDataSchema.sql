--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3 (Ubuntu 16.3-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.3 (Ubuntu 16.3-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: diesel_manage_updated_at(regclass); Type: FUNCTION; Schema: public; Owner: dataowner
--

CREATE FUNCTION public.diesel_manage_updated_at(_tbl regclass) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %s
                    FOR EACH ROW EXECUTE PROCEDURE diesel_set_updated_at()', _tbl);
END;
$$;


ALTER FUNCTION public.diesel_manage_updated_at(_tbl regclass) OWNER TO dataowner;

--
-- Name: diesel_set_updated_at(); Type: FUNCTION; Schema: public; Owner: dataowner
--

CREATE FUNCTION public.diesel_set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        NEW IS DISTINCT FROM OLD AND
        NEW.updated_at IS NOT DISTINCT FROM OLD.updated_at
    ) THEN
        NEW.updated_at := current_timestamp;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.diesel_set_updated_at() OWNER TO dataowner;

--
-- Name: refresh_materialized_view(); Type: FUNCTION; Schema: public; Owner: dataowner
--

CREATE FUNCTION public.refresh_materialized_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   PERFORM refresh_materialized_views();
   RETURN NULL;
END;
$$;


ALTER FUNCTION public.refresh_materialized_view() OWNER TO dataowner;

--
-- Name: refresh_materialized_views(); Type: FUNCTION; Schema: public; Owner: dataowner
--

CREATE FUNCTION public.refresh_materialized_views() RETURNS void
    LANGUAGE plpgsql
    AS $_$
DECLARE class_name TEXT; column_types TEXT; query TEXT; view_name TEXT; BEGIN
FOR class_name IN SELECT DISTINCT className FROM Class LOOP
   SELECT string_agg(quote_ident(fieldName) || ' VARCHAR(1000)', ', ')
   INTO column_types
   FROM (
      SELECT DISTINCT fieldName
      FROM CustomFields
      WHERE className = class_name
   ) AS sub;
   RAISE NOTICE 'column_types: %', column_types;

   view_name := quote_ident(class_name || '_products');

   IF column_types IS NULL THEN
     query := format($f$
         CREATE MATERIALIZED VIEW %s AS
         SELECT p.productId, p.class, p.description, p.cost, p.currentPrice, p.inventory
        FROM Product p
        WHERE p.class = '%s'
      $f$, view_name, class_name);
ELSE
   query := format($f$
      CREATE MATERIALIZED VIEW %s AS
      SELECT *
      FROM crosstab(
         'SELECT p.productId, p.class, p.description, p.cost, p.currentPrice, p.inventory, cf.fieldName, cfd.fieldValue
          FROM product p
          LEFT JOIN CustomFieldData cfd ON p.productId = cfd.productId
          LEFT JOIN customFields cf ON cf.customFieldsId = cfd.customFieldsId
          WHERE p.Class = ''%s''',
         'SELECT DISTINCT fieldName FROM CustomFields WHERE className = ''%s'''
      ) AS ct (product_id INT, class VARCHAR(15), description VARCHAR(100), cost MONEY, currentPrice MONEY, inventory INT, %s)
   $f$, view_name, class_name, class_name, column_types);
END IF;

RAISE NOTICE 'query: %', query;

EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS %s', view_name);
EXECUTE query;
END LOOP;
END $_$;


ALTER FUNCTION public.refresh_materialized_views() OWNER TO dataowner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: __diesel_schema_migrations; Type: TABLE; Schema: public; Owner: dataowner
--

CREATE TABLE public.__diesel_schema_migrations (
    version character varying(50) NOT NULL,
    run_on timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.__diesel_schema_migrations OWNER TO dataowner;

--
-- Name: product; Type: TABLE; Schema: public; Owner: dataowner
--

CREATE TABLE public.product (
    productid integer NOT NULL,
    class character varying(15) NOT NULL,
    description character varying(100) NOT NULL,
    cost money NOT NULL,
    currentprice money NOT NULL,
    inventory integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.product OWNER TO dataowner;

--
-- Name: board game_products; Type: MATERIALIZED VIEW; Schema: public; Owner: dataowner
--

CREATE MATERIALIZED VIEW public."board game_products" AS
 SELECT productid,
    class,
    description,
    cost,
    currentprice,
    inventory
   FROM public.product p
  WHERE ((class)::text = 'board game'::text)
  WITH NO DATA;


ALTER MATERIALIZED VIEW public."board game_products" OWNER TO dataowner;

--
-- Name: book_products; Type: MATERIALIZED VIEW; Schema: public; Owner: dataowner
--

CREATE MATERIALIZED VIEW public.book_products AS
 SELECT product_id,
    class,
    description,
    cost,
    currentprice,
    inventory,
    "Author",
    "Publication"
   FROM public.crosstab('SELECT p.productId, p.class, p.description, p.cost, p.currentPrice, p.inventory, cf.fieldName, cfd.fieldValue
          FROM product p
          LEFT JOIN CustomFieldData cfd ON p.productId = cfd.productId
          LEFT JOIN customFields cf ON cf.customFieldsId = cfd.customFieldsId
          WHERE p.Class = ''book'''::text, 'SELECT DISTINCT fieldName FROM CustomFields WHERE className = ''book'''::text) ct(product_id integer, class character varying(15), description character varying(100), cost money, currentprice money, inventory integer, "Author" character varying(1000), "Publication" character varying(1000))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.book_products OWNER TO dataowner;

--
-- Name: class; Type: TABLE; Schema: public; Owner: dataowner
--

CREATE TABLE public.class (
    classname character varying(15) NOT NULL
);


ALTER TABLE public.class OWNER TO dataowner;

--
-- Name: customfielddata; Type: TABLE; Schema: public; Owner: dataowner
--

CREATE TABLE public.customfielddata (
    productid integer NOT NULL,
    customfieldsid integer NOT NULL,
    fieldvalue character varying(1000)
);


ALTER TABLE public.customfielddata OWNER TO dataowner;

--
-- Name: customfields; Type: TABLE; Schema: public; Owner: dataowner
--

CREATE TABLE public.customfields (
    customfieldsid integer NOT NULL,
    classname character varying(15) NOT NULL,
    fieldname character varying(15) NOT NULL,
    fieldtype character varying(10) NOT NULL
);


ALTER TABLE public.customfields OWNER TO dataowner;

--
-- Name: customfields_id_seq; Type: SEQUENCE; Schema: public; Owner: dataowner
--

ALTER TABLE public.customfields ALTER COLUMN customfieldsid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.customfields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: grocery_products; Type: MATERIALIZED VIEW; Schema: public; Owner: dataowner
--

CREATE MATERIALIZED VIEW public.grocery_products AS
 SELECT product_id,
    class,
    description,
    cost,
    currentprice,
    inventory,
    "Expiration Date"
   FROM public.crosstab('SELECT p.productId, p.class, p.description, p.cost, p.currentPrice, p.inventory, cf.fieldName, cfd.fieldValue
          FROM product p
          LEFT JOIN CustomFieldData cfd ON p.productId = cfd.productId
          LEFT JOIN customFields cf ON cf.customFieldsId = cfd.customFieldsId
          WHERE p.Class = ''grocery'''::text, 'SELECT DISTINCT fieldName FROM CustomFields WHERE className = ''grocery'''::text) ct(product_id integer, class character varying(15), description character varying(100), cost money, currentprice money, inventory integer, "Expiration Date" character varying(1000))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.grocery_products OWNER TO dataowner;

--
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: dataowner
--

ALTER TABLE public.product ALTER COLUMN productid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: __diesel_schema_migrations __diesel_schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.__diesel_schema_migrations
    ADD CONSTRAINT __diesel_schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: class class_pkey; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.class
    ADD CONSTRAINT class_pkey PRIMARY KEY (classname);


--
-- Name: customfielddata customfielddata_pkey; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfielddata
    ADD CONSTRAINT customfielddata_pkey PRIMARY KEY (productid, customfieldsid);


--
-- Name: customfields customfields_classname_fieldname_key; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfields
    ADD CONSTRAINT customfields_classname_fieldname_key UNIQUE (classname, fieldname);


--
-- Name: customfields customfields_pkey; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfields
    ADD CONSTRAINT customfields_pkey PRIMARY KEY (customfieldsid);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (productid);


--
-- Name: customfielddata refresh_custom_field_data_trigger; Type: TRIGGER; Schema: public; Owner: dataowner
--

CREATE TRIGGER refresh_custom_field_data_trigger AFTER INSERT OR DELETE OR UPDATE ON public.customfielddata FOR EACH ROW EXECUTE FUNCTION public.refresh_materialized_view();


--
-- Name: customfields refresh_custom_fields_trigger; Type: TRIGGER; Schema: public; Owner: dataowner
--

CREATE TRIGGER refresh_custom_fields_trigger AFTER INSERT OR DELETE OR UPDATE ON public.customfields FOR EACH ROW EXECUTE FUNCTION public.refresh_materialized_view();


--
-- Name: product refresh_products_trigger; Type: TRIGGER; Schema: public; Owner: dataowner
--

CREATE TRIGGER refresh_products_trigger AFTER INSERT OR DELETE OR UPDATE ON public.product FOR EACH ROW EXECUTE FUNCTION public.refresh_materialized_view();


--
-- Name: product fk_class; Type: FK CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT fk_class FOREIGN KEY (class) REFERENCES public.class(classname);


--
-- Name: customfields fk_class; Type: FK CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfields
    ADD CONSTRAINT fk_class FOREIGN KEY (classname) REFERENCES public.class(classname);


--
-- Name: customfielddata fk_customfieldid; Type: FK CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfielddata
    ADD CONSTRAINT fk_customfieldid FOREIGN KEY (customfieldsid) REFERENCES public.customfields(customfieldsid);


--
-- Name: customfielddata fk_product; Type: FK CONSTRAINT; Schema: public; Owner: dataowner
--

ALTER TABLE ONLY public.customfielddata
    ADD CONSTRAINT fk_product FOREIGN KEY (productid) REFERENCES public.product(productid);


--
-- PostgreSQL database dump complete
--

