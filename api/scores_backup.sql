--
-- PostgreSQL database dump
--

\restrict rqamlPohHwVN1NeSGCkjex67X4iy2S8yduJrcPzxORgy8X0ALxVWlW2hh3Xr9l2

-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: scores; Type: TABLE; Schema: public; Owner: clickfast
--

CREATE TABLE public.scores (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    score integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT scores_score_check CHECK ((score >= 0))
);


ALTER TABLE public.scores OWNER TO clickfast;

--
-- Name: scores_id_seq; Type: SEQUENCE; Schema: public; Owner: clickfast
--

CREATE SEQUENCE public.scores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scores_id_seq OWNER TO clickfast;

--
-- Name: scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: clickfast
--

ALTER SEQUENCE public.scores_id_seq OWNED BY public.scores.id;


--
-- Name: scores id; Type: DEFAULT; Schema: public; Owner: clickfast
--

ALTER TABLE ONLY public.scores ALTER COLUMN id SET DEFAULT nextval('public.scores_id_seq'::regclass);


--
-- Data for Name: scores; Type: TABLE DATA; Schema: public; Owner: clickfast
--

COPY public.scores (id, username, score, created_at) FROM stdin;
1	Orokia	15	2026-10-26 14:57:14.823652+00
\.


--
-- Name: scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: clickfast
--

SELECT pg_catalog.setval('public.scores_id_seq', 1, true);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: clickfast
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict rqamlPohHwVN1NeSGCkjex67X4iy2S8yduJrcPzxORgy8X0ALxVWlW2hh3Xr9l2

