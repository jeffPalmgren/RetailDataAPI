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
-- Data for Name: __diesel_schema_migrations; Type: TABLE DATA; Schema: public; Owner: dataowner
--

COPY public.__diesel_schema_migrations (version, run_on) FROM stdin;
00000000000000	2024-06-13 19:14:58.221821
\.


--
-- Data for Name: class; Type: TABLE DATA; Schema: public; Owner: dataowner
--

COPY public.class (classname) FROM stdin;
grocery
book
board game
\.


--
-- Data for Name: customfields; Type: TABLE DATA; Schema: public; Owner: dataowner
--

COPY public.customfields (customfieldsid, classname, fieldname, fieldtype) FROM stdin;
1	grocery	Expiration Date	dateOnly
2	book	Author	text
3	book	Publication	int
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: dataowner
--

COPY public.product (productid, class, description, cost, currentprice, inventory) FROM stdin;
1	grocery	noodles	$0.98	$1.98	17
2	grocery	flour	$2.15	$4.42	2
3	grocery	milk	$3.12	$4.89	14
4	grocery	bread	$0.54	$2.18	10
5	grocery	soda	$8.07	$12.32	25
6	grocery	cognac	$83.00	$212.14	0
7	book	The Secret Garden	$12.50	$20.32	2
8	book	The Phantom of the Opera	$10.56	$35.91	12
9	book	The Island of Dr Moreau	$9.02	$15.05	7
11	board game	Apples to Apples	$15.87	$28.23	1
12	board game	The Farming Game	$26.65	$53.76	5
13	board game	Monopoly	$19.57	$25.52	9
14	board game	Chess	$8.14	$15.23	3
15	board game	Stratego	$12.42	$23.56	3
10	book	Peter and Wendy	$13.41	$21.55	9
\.


--
-- Data for Name: customfielddata; Type: TABLE DATA; Schema: public; Owner: dataowner
--

COPY public.customfielddata (productid, customfieldsid, fieldvalue) FROM stdin;
10	2	J.M. Berrie
10	3	1911
1	1	2025-5-17
3	1	2024-07-20
7	2	Frances Hodgson Burnett
7	3	1911
\.


--
-- Name: customfields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dataowner
--

SELECT pg_catalog.setval('public.customfields_id_seq', 3, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dataowner
--

SELECT pg_catalog.setval('public.product_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--

