-- ========================================================
-- Workshop 6: Resilient Waiting Queue Database Migration
-- ========================================================

-- 1. Extend the existing clients table with geolocation columns
ALTER TABLE public.clients
ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_accuracy_m DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_captured_at TIMESTAMPTZ;

-- 2. Add validation constraints for coordinates
ALTER TABLE public.clients
DROP CONSTRAINT IF EXISTS valid_latitude;

ALTER TABLE public.clients
ADD CONSTRAINT valid_latitude
CHECK (lat IS NULL OR lat BETWEEN -90 AND 90);

ALTER TABLE public.clients
DROP CONSTRAINT IF EXISTS valid_longitude;

ALTER TABLE public.clients
ADD CONSTRAINT valid_longitude
CHECK (lng IS NULL OR lng BETWEEN -180 AND 180);

-- 3. Database Transaction Setup for Authoritative Queue Numbers
CREATE OR REPLACE FUNCTION register_queue_client(
  p_id UUID,
  p_name TEXT,
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_accuracy DOUBLE PRECISION,
  p_created_at TIMESTAMPTZ
)
RETURNS SETOF public.clients AS $$
BEGIN
  RETURN QUERY
  INSERT INTO public.clients (
    id,
    name,
    lat,
    lng,
    location_accuracy_m,
    created_at
  )
  VALUES (
    p_id,
    p_name,
    p_lat,
    p_lng,
    p_accuracy,
    p_created_at
  )
  ON CONFLICT (id) DO UPDATE
  SET name = EXCLUDED.name
  RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
