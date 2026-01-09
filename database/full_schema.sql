-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- Enable Trigram extension for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

/*
-- ============================================
-- DROP ALL TABLES & RESET DATABASE (Uncomment when needed)
-- ============================================
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
*/

-- 1. ENUM Types
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'pilgrim', 'local_guide');
    CREATE TYPE user_status AS ENUM ('active', 'banned');
    CREATE TYPE site_region AS ENUM ('Bac', 'Trung', 'Nam');
    CREATE TYPE site_type AS ENUM ('church', 'shrine', 'monastery', 'center', 'other');
    CREATE TYPE planner_status AS ENUM ('planning', 'ongoing', 'completed');
    CREATE TYPE planner_role AS ENUM ('viewer', 'editor');
    CREATE TYPE journal_privacy AS ENUM ('private', 'public');
    CREATE TYPE budget_level AS ENUM ('budget', 'standard', 'luxury');
    CREATE TYPE site_status AS ENUM ('pending', 'approved', 'rejected', 'hidden');
    CREATE TYPE content_status AS ENUM ('draft', 'published', 'pending', 'approved', 'rejected', 'hidden');
    CREATE TYPE media_type AS ENUM ('image', 'video', 'virtual_tour');
    CREATE TYPE ai_type AS ENUM ('prayer', 'verse', 'summary', 'sentiment');
    CREATE TYPE ai_source_type AS ENUM ('journal', 'planner', 'post', 'chat');
    CREATE TYPE group_privacy AS ENUM ('public', 'private', 'closed');
    CREATE TYPE group_member_role AS ENUM ('admin', 'member');
    CREATE TYPE report_reason AS ENUM ('spam', 'inappropriate', 'harassment', 'other');
    CREATE TYPE report_status AS ENUM ('pending', 'resolved', 'dismissed');
    CREATE TYPE sos_status AS ENUM ('pending', 'accepted', 'resolved', 'cancelled');
    CREATE TYPE invite_status AS ENUM ('pending', 'accepted', 'rejected', 'expired');
    CREATE TYPE participant_status AS ENUM ('going', 'interested');
    CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Trigger Function for Auto-Update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger Function for Auto-Update likes_count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE posts SET likes_count = likes_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    full_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    date_of_birth DATE,
    role user_role NOT NULL DEFAULT 'pilgrim',
    status user_status NOT NULL DEFAULT 'active',
    language VARCHAR(5) NOT NULL DEFAULT 'vi',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger for users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 2.1 Refresh Tokens 
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2.2 Blacklisted Tokens 
CREATE TABLE IF NOT EXISTS blacklisted_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2.3 Password Resets
CREATE TABLE IF NOT EXISTS password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2.4 AI Generated Contents
CREATE TABLE IF NOT EXISTS ai_generated_contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type ai_type NOT NULL,
    source_type ai_source_type, -- Context of generation
    source_id UUID, -- ID of the related content (journal_id, planner_id, etc.)
    prompt TEXT,
    result TEXT, -- Or JSONB if structured
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2.5 Verification Requests (Local Guide Application)
CREATE TABLE IF NOT EXISTS verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Option 1: Chon site co san
    requested_site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
    
    -- Option 2: De xuat site moi (neu requested_site_id NULL)
    proposed_site_name VARCHAR(255),
    proposed_site_address TEXT,
    proposed_site_province VARCHAR(100),
    proposed_site_district VARCHAR(100),
    proposed_site_region site_region,
    proposed_site_type site_type,
    proposed_site_latitude DECIMAL(9,6) CHECK (proposed_site_latitude IS NULL OR (proposed_site_latitude BETWEEN -90 AND 90)),
    proposed_site_longitude DECIMAL(9,6) CHECK (proposed_site_longitude IS NULL OR (proposed_site_longitude BETWEEN -180 AND 180)),
    proposed_site_description TEXT,
    
    certificate_url TEXT, -- Giay chung nhan / The HDV / Giay gioi thieu
    introduction TEXT,    -- Gioi thieu ngan
    status verification_status DEFAULT 'pending',
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Unique index: Chi cho phep 1 pending request/user (user co the apply lai sau khi bi reject)
CREATE UNIQUE INDEX IF NOT EXISTS uq_verification_requests_user_pending
ON verification_requests(user_id) 
WHERE status = 'pending';

-- Performance indexes for common queries
CREATE INDEX IF NOT EXISTS idx_verification_requests_status 
ON verification_requests(status);

CREATE INDEX IF NOT EXISTS idx_verification_requests_site 
ON verification_requests(requested_site_id) 
WHERE requested_site_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_verification_requests_reviewer 
ON verification_requests(reviewed_by) 
WHERE reviewed_by IS NOT NULL;

-- Check constraint: Phai chon 1 trong 2 (site co san HOAC de xuat moi)
-- Neu de xuat moi: bat buoc co name, province, region, type
ALTER TABLE verification_requests
ADD CONSTRAINT chk_site_selection
CHECK (
  (requested_site_id IS NOT NULL AND proposed_site_name IS NULL) OR
  (requested_site_id IS NULL AND 
   proposed_site_name IS NOT NULL AND 
   proposed_site_province IS NOT NULL AND
   proposed_site_region IS NOT NULL AND 
   proposed_site_type IS NOT NULL)
);

-- Check constraint for rejection reason
ALTER TABLE verification_requests
ADD CONSTRAINT chk_verification_reason
CHECK (
  (status <> 'rejected'::verification_status OR rejection_reason IS NOT NULL)
);

-- Trigger for verification_requests
DROP TRIGGER IF EXISTS update_verification_requests_updated_at ON verification_requests;
CREATE TRIGGER update_verification_requests_updated_at
    BEFORE UPDATE ON verification_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 2.6 Local Guides (Approved Guides)
CREATE TABLE IF NOT EXISTS local_guides (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    note TEXT
);

CREATE INDEX IF NOT EXISTS idx_local_guides_site
ON local_guides(site_id);

-- 3. SITE MODULE
-- 3.1 Sites Table (Dia Diem)
CREATE TABLE IF NOT EXISTS sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    history TEXT,
    address TEXT,
    province VARCHAR(100),
    district VARCHAR(100),
    latitude DECIMAL(9,6) CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
    longitude DECIMAL(9,6) CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
    region site_region NOT NULL,
    type site_type NOT NULL,
    patron_saint VARCHAR(255),
    cover_image TEXT,
    opening_hours JSONB,
    contact_info JSONB,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status site_status DEFAULT 'pending',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger for sites
DROP TRIGGER IF EXISTS update_sites_updated_at ON sites;
CREATE TRIGGER update_sites_updated_at
    BEFORE UPDATE ON sites
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 3.2 Site Media
CREATE TABLE IF NOT EXISTS site_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    type media_type DEFAULT 'image',
    caption TEXT,
    is_main BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_site_media_main
ON site_media(site_id)
WHERE is_main = TRUE;

-- 3.3 Mass Schedules
CREATE TABLE IF NOT EXISTS mass_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    day_of_week INT CHECK (day_of_week IS NULL OR (day_of_week BETWEEN 0 AND 6)),
    time TIME NOT NULL,
    language VARCHAR(50) DEFAULT 'Tiếng Việt',
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3.4 Events
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    banner_url TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    status site_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS event_participants (
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status participant_status DEFAULT 'going',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id)
);

-- 4. Planner Modules
CREATE TABLE IF NOT EXISTS planners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    start_date DATE,
    number_of_days INT DEFAULT 1,
    number_of_people INT DEFAULT 1,
    transportation VARCHAR(100),
    budget_level budget_level DEFAULT 'standard',
    status planner_status DEFAULT 'planning',
    is_public BOOLEAN DEFAULT FALSE,
    share_token VARCHAR(50) UNIQUE DEFAULT NULL, -- For sharing link
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS planner_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planner_id UUID NOT NULL REFERENCES planners(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL, -- Invite via email (Targeted invite)
    token VARCHAR(100) NOT NULL,
    role planner_role DEFAULT 'viewer',
    status invite_status DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS planner_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    planner_id UUID NOT NULL REFERENCES planners(id) ON DELETE CASCADE,
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    day_number INT DEFAULT 1,
    order_index INT DEFAULT 1,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE planner_items
    ADD CONSTRAINT uq_planner_items_order UNIQUE (planner_id, day_number, order_index);

CREATE TABLE IF NOT EXISTS planner_members (
    planner_id UUID REFERENCES planners(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role planner_role DEFAULT 'viewer',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (planner_id, user_id)
);

-- 5. Interaction Modules
CREATE TABLE IF NOT EXISTS user_favorites (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, site_id)
);

CREATE TABLE IF NOT EXISTS user_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id) ON DELETE CASCADE,
    checkin_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    note TEXT
);

-- 6. Journal & Community
CREATE TABLE IF NOT EXISTS journals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id) ON DELETE SET NULL,
    title TEXT,
    content TEXT,
    audio_url TEXT,
    image_url TEXT,
    privacy journal_privacy DEFAULT 'private',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    privacy group_privacy DEFAULT 'public',
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS group_members (
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role group_member_role DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);

-- Trigger for groups
DROP TRIGGER IF EXISTS update_groups_updated_at ON groups;
CREATE TRIGGER update_groups_updated_at
    BEFORE UPDATE ON groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE, -- Nullable if personal wall post
    content TEXT NOT NULL,
    image_urls TEXT[],
    likes_count INT DEFAULT 0,
    status content_status DEFAULT 'published',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger for posts auto update
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE IF NOT EXISTS post_likes (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status content_status DEFAULT 'published', 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Moderation & Reports
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(id) ON DELETE SET NULL,
    target_type VARCHAR(50) NOT NULL, -- post, comment, user, journal, group
    target_id UUID NOT NULL,
    reason report_reason NOT NULL,
    description TEXT,
    status report_status DEFAULT 'pending',
    resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Trigger for reports
DROP TRIGGER IF EXISTS update_reports_updated_at ON reports;
CREATE TRIGGER update_reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for planners
DROP TRIGGER IF EXISTS update_planners_updated_at ON planners;
CREATE TRIGGER update_planners_updated_at
    BEFORE UPDATE ON planners
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for journals
DROP TRIGGER IF EXISTS update_journals_updated_at ON journals;
CREATE TRIGGER update_journals_updated_at
    BEFORE UPDATE ON journals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Additional Unique Indexes
CREATE UNIQUE INDEX IF NOT EXISTS uq_planner_invites_token ON planner_invites(token);
-- GIN Index for Fast Text Search (requires pg_trgm)
CREATE INDEX IF NOT EXISTS idx_sites_name_trgm ON sites USING GIN (name gin_trgm_ops);

-- Trigger for syncing likes_count
DROP TRIGGER IF EXISTS trigger_update_post_likes_count ON post_likes;
CREATE TRIGGER trigger_update_post_likes_count
    AFTER INSERT OR DELETE ON post_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_post_likes_count();

-- 8. SOS & Emergency
CREATE TABLE IF NOT EXISTS sos_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id), -- If at a specific site
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    message TEXT,
    contact_phone VARCHAR(20),
    status sos_status DEFAULT 'pending',
    notes TEXT, -- Notes from guide/admin
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_sites_search ON sites(name, province, district);
CREATE INDEX IF NOT EXISTS idx_sites_coords ON sites(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_sites_region_type ON sites(region, type);
CREATE INDEX IF NOT EXISTS idx_sites_status ON sites(status);
CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_planners_user ON planners(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_group ON posts(group_id);
CREATE INDEX IF NOT EXISTS idx_ai_contents_user ON ai_generated_contents(user_id);
CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_requests(status);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);
