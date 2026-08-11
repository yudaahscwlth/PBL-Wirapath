-- WIRAKARSA / WIRAPATH DATABASE SCHEMA & PRE-SEEDED DATA
-- Strictly configured for 6 Target Roles with 3 Dedicated Categories, 5 Questions per Category, and 3 Dedicated Mini Projects per Role.

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(255) PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255),
  role VARCHAR(50) DEFAULT 'user',
  target_role VARCHAR(255) DEFAULT 'Frontend Developer',
  university VARCHAR(255),
  field_of_study VARCHAR(255),
  graduation_year VARCHAR(50),
  cv_url TEXT,
  transcript_url TEXT,
  readiness_score DECIMAL(5, 2) DEFAULT 0.00,
  github_username VARCHAR(255) NULL,
  github_languages JSON NULL,
  github_readiness_score DECIMAL(5,2) NULL,
  github_last_synced_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS assessment_categories (
  id VARCHAR(255) PRIMARY KEY,
  slug VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(100),
  color VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS role_category_mapping (
  id VARCHAR(255) PRIMARY KEY,
  target_role_pattern VARCHAR(255) NOT NULL,
  category_slug VARCHAR(255) NOT NULL,
  priority INT DEFAULT 1,
  FOREIGN KEY (category_slug) REFERENCES assessment_categories(slug) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS assessment_questions (
  id VARCHAR(255) PRIMARY KEY,
  category_id VARCHAR(255) NOT NULL,
  question_type VARCHAR(50) DEFAULT 'multiple_choice',
  question_text TEXT NOT NULL,
  options JSON,
  correct_answer VARCHAR(255) NOT NULL,
  explanation TEXT,
  FOREIGN KEY (category_id) REFERENCES assessment_categories(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_assessments (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  time_taken_seconds INT DEFAULT 0,
  total_questions INT DEFAULT 0,
  correct_answers INT DEFAULT 0,
  score_percentage DECIMAL(5, 2) DEFAULT 0.00,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_assessment_answers (
  id VARCHAR(255) PRIMARY KEY DEFAULT (UUID()),
  assessment_id VARCHAR(255) NOT NULL,
  question_id VARCHAR(255) NOT NULL,
  user_answer TEXT,
  is_correct BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (assessment_id) REFERENCES user_assessments(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES assessment_questions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cv_screenings (
  id VARCHAR(255) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(255) NOT NULL,
  cv_url TEXT,
  score INT DEFAULT 0,
  summary TEXT,
  strengths JSON,
  weaknesses JSON,
  recommendations JSON,
  already_good JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS simulations (
  id VARCHAR(255) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(255) NOT NULL,
  type VARCHAR(50) DEFAULT 'interview',
  company_name VARCHAR(255),
  status VARCHAR(50) DEFAULT 'ongoing',
  result JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- MINI PROJECTS TABLES
CREATE TABLE IF NOT EXISTS mini_projects (
  id VARCHAR(255) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  difficulty VARCHAR(50) DEFAULT 'Intermediate',
  estimated_hours INT DEFAULT 4,
  points INT DEFAULT 100,
  tech_stack JSON,
  tasks JSON,
  sort_order INT DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mini_project_role_mapping (
  id VARCHAR(255) PRIMARY KEY,
  mini_project_id VARCHAR(255) NOT NULL,
  target_role_pattern VARCHAR(255) NOT NULL,
  priority INT DEFAULT 1,
  FOREIGN KEY (mini_project_id) REFERENCES mini_projects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_mini_project_submissions (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  mini_project_id VARCHAR(255) NOT NULL,
  submission_url TEXT,
  github_repo_url TEXT,
  notes TEXT,
  status VARCHAR(50) DEFAULT 'in_progress',
  overall_score INT DEFAULT 0,
  feedback TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (mini_project_id) REFERENCES mini_projects(id) ON DELETE CASCADE
);

-- ==========================================
-- PRE-SEED DATA
-- ==========================================

-- 1. Assessment Categories (18 Dedicated Categories)
INSERT IGNORE INTO assessment_categories (id, slug, name, description, icon, color) VALUES
-- Frontend Developer Categories
('cat-fe-frameworks', 'fe_frameworks', 'React & Web Frameworks', 'Assess React hooks, virtual DOM, component lifecycles, and modern SPA architecture.', 'Layout', 'blue'),
('cat-fe-css', 'fe_css_responsive', 'CSS Architecture & Layouts', 'Assess Flexbox, Grid, Tailwind CSS, responsive viewports, and accessibility.', 'Palette', 'blue'),
('cat-fe-dom', 'fe_performance_dom', 'DOM & Client Performance', 'Assess browser rendering performance, DOM optimization, and client state.', 'Zap', 'blue'),

-- Backend Developer Categories
('cat-be-api', 'be_server_api', 'REST APIs & Server Logic', 'Assess Node.js runtime, Express routing, middleware pipelines, and API design.', 'Server', 'purple'),
('cat-be-sql', 'be_database_sql', 'Database & SQL Optimization', 'Assess relational schemas, indexing, ACID transactions, and query profiling.', 'Database', 'purple'),
('cat-be-sec', 'be_security_auth', 'API Security & Authentication', 'Assess JWT stateless auth, password hashing, CORS, and OWASP mitigation.', 'Shield', 'purple'),

-- Fullstack Developer Categories
('cat-fs-web', 'fs_frontend_web', 'Fullstack Frontend Web', 'Assess client-side state, API integration, UI component lifecycle, and SSR/SSG.', 'Layers', 'indigo'),
('cat-fs-server', 'fs_backend_api', 'Fullstack Backend & APIs', 'Assess microservices, server routing, async queues, and API gateways.', 'Cpu', 'indigo'),
('cat-fs-orm', 'fs_database_orm', 'Database & ORM Integration', 'Assess schema migrations, ORM query builders, data integrity, and indexing.', 'HardDrive', 'indigo'),

-- Data Scientist Categories
('cat-ds-python', 'ds_python_libraries', 'Python Data Stack', 'Assess NumPy vectorization, Pandas DataFrames, data cleaning, and exploration.', 'BarChart2', 'emerald'),
('cat-ds-ml', 'ds_machine_learning', 'Machine Learning & Models', 'Assess supervised/unsupervised algorithms, cross-validation, and accuracy metrics.', 'Brain', 'emerald'),
('cat-ds-pipe', 'ds_data_engineering', 'Data Engineering & SQL', 'Assess ETL pipelines, SQL aggregation, feature engineering, and model metrics.', 'GitBranch', 'emerald'),

-- UI/UX Designer Categories
('cat-ux-figma', 'ux_figma_design_systems', 'Figma & Design Systems', 'Assess Auto Layout, variant components, design tokens, and style guide structures.', 'Figma', 'pink'),
('cat-ux-heuristics', 'ux_principles_usability', 'UX Principles & Usability (HCI)', 'Assess Jakob Nielsen heuristics, visual hierarchy, contrast ratios, and WCAG accessibility.', 'Eye', 'pink'),
('cat-ux-research', 'ux_research_prototyping', 'User Research & Wireframing', 'Assess user interviews, persona mapping, wireframing, and interactive prototyping.', 'PenTool', 'pink'),

-- Mobile Developer Categories
('cat-mb-flutter', 'mb_flutter_dart', 'Flutter & Dart Fundamentals', 'Assess Flutter widget tree, Dart async programming, build contexts, and layouts.', 'Smartphone', 'cyan'),
('cat-mb-state', 'mb_crossplatform_state', 'Mobile State & Navigation', 'Assess Riverpod, Bloc, Go Router navigation, and app lifecycle state.', 'Repeat', 'cyan'),
('cat-mb-native', 'mb_native_api_storage', 'Native Device APIs & Storage', 'Assess camera/location plugins, SQLite/Hive local storage, and offline sync.', 'HardDrive', 'cyan');

-- 2. Role Category Mapping (Strictly 3 Dedicated Categories Per Role)
INSERT IGNORE INTO role_category_mapping (id, target_role_pattern, category_slug, priority) VALUES
-- Frontend Developer (3)
(UUID(), 'Frontend Developer', 'fe_frameworks', 1),
(UUID(), 'Frontend Developer', 'fe_css_responsive', 2),
(UUID(), 'Frontend Developer', 'fe_performance_dom', 3),

-- Backend Developer (3)
(UUID(), 'Backend Developer', 'be_server_api', 1),
(UUID(), 'Backend Developer', 'be_database_sql', 2),
(UUID(), 'Backend Developer', 'be_security_auth', 3),

-- Fullstack Developer (3)
(UUID(), 'Fullstack Developer', 'fs_frontend_web', 1),
(UUID(), 'Fullstack Developer', 'fs_backend_api', 2),
(UUID(), 'Fullstack Developer', 'fs_database_orm', 3),

-- Data Scientist (3)
(UUID(), 'Data Scientist', 'ds_python_libraries', 1),
(UUID(), 'Data Scientist', 'ds_machine_learning', 2),
(UUID(), 'Data Scientist', 'ds_data_engineering', 3),

-- UI/UX Designer (3)
(UUID(), 'UI/UX Designer', 'ux_figma_design_systems', 1),
(UUID(), 'UI/UX Designer', 'ux_principles_usability', 2),
(UUID(), 'UI/UX Designer', 'ux_research_prototyping', 3),

-- Mobile Developer (3)
(UUID(), 'Mobile Developer', 'mb_flutter_dart', 1),
(UUID(), 'Mobile Developer', 'mb_crossplatform_state', 2),
(UUID(), 'Mobile Developer', 'mb_native_api_storage', 3);

-- 3. Assessment Questions (5 Questions Per Category: 3 MC + 2 Yes/No)

-- ==================== 1. FRONTEND DEVELOPER QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
('q-fe-fw-1', 'cat-fe-frameworks', 'multiple_choice', 'Which React hook is specifically designed to memoize computed values across render passes to prevent expensive recalculated executions?', '[{"id":"A","text":"useEffect"},{"id":"B","text":"useCallback"},{"id":"C","text":"useMemo"},{"id":"D","text":"useRef"}]', 'C', 'useMemo returns a memoized value, recomputing it only when specified dependency variables change.'),
('q-fe-fw-2', 'cat-fe-frameworks', 'multiple_choice', 'In Vue 3 Composition API, which function creates a deeply reactive state object?', '[{"id":"A","text":"ref()"},{"id":"B","text":"reactive()"},{"id":"C","text":"computed()"},{"id":"D","text":"provide()"}]', 'B', 'reactive() returns a reactive proxy of the object, tracking deep property mutations.'),
('q-fe-fw-3', 'cat-fe-frameworks', 'multiple_choice', 'In React, what is the primary purpose of passing a unique `key` prop to elements in an array iteration?', '[{"id":"A","text":"To style elements individually in CSS"},{"id":"B","text":"To help React Reconciliation identify which items changed, added, or removed"},{"id":"C","text":"To encrypt component state in memory"},{"id":"D","text":"To bypass component lifecycle checks"}]', 'B', 'Keys give elements a stable identity so React Diffing algorithm reorders rather than re-creates DOM nodes.'),
('q-fe-fw-4', 'cat-fe-frameworks', 'yes_no', 'Do you routinely utilize React.memo or React PureComponent to prevent redundant child component rerenders in large web applications?', NULL, 'yes', 'React.memo skips component rendering if props have not changed.'),
('q-fe-fw-5', 'cat-fe-frameworks', 'yes_no', 'Have you configured custom React Hooks to abstract and reuse asynchronous data fetching and API state logic across UI pages?', NULL, 'yes', 'Custom hooks encapsulate complex side-effects and keep component view files clean.'),

('q-fe-css-1', 'cat-fe-css', 'multiple_choice', 'When designing for WCAG 2.1 AA level conformance, what is the minimum required color contrast ratio for standard body text?', '[{"id":"A","text":"3.0:1"},{"id":"B","text":"4.5:1"},{"id":"C","text":"7.0:1"},{"id":"D","text":"2.1:1"}]', 'B', 'WCAG 2.1 AA level requires a contrast ratio of at least 4.5:1 for standard body text.'),
('q-fe-css-2', 'cat-fe-css', 'multiple_choice', 'Which CSS layout module is specifically designed for 2-dimensional item placement (rows and columns simultaneously)?', '[{"id":"A","text":"Flexbox"},{"id":"B","text":"CSS Grid"},{"id":"C","text":"Float Layout"},{"id":"D","text":"Absolute Positioning"}]', 'B', 'CSS Grid is a 2-dimensional layout engine controlling both columns and rows.'),
('q-fe-css-3', 'cat-fe-css', 'multiple_choice', 'In CSS Flexbox, which property controls alignment along the main axis?', '[{"id":"A","text":"align-items"},{"id":"B","text":"justify-content"},{"id":"C","text":"align-content"},{"id":"D","text":"flex-wrap"}]', 'B', 'justify-content distributes space along the flex container main axis.'),
('q-fe-css-4', 'cat-fe-css', 'yes_no', 'Do you routinely use semantic HTML tags (<main>, <article>, <section>) instead of generic <div> tags for screen readers?', NULL, 'yes', 'Semantic HTML optimizes screen reader navigation and web indexing.'),
('q-fe-css-5', 'cat-fe-css', 'yes_no', 'Have you configured CSS custom properties (variables) or Tailwind themes to support native responsive dark mode toggling?', NULL, 'yes', 'CSS variables allow seamless theme switching across components.'),

('q-fe-dom-1', 'cat-fe-dom', 'multiple_choice', 'Which browser Web API method schedules a callback to execute right before the next browser repaint for smooth animations?', '[{"id":"A","text":"setTimeout()"},{"id":"B","text":"requestAnimationFrame()"},{"id":"C","text":"requestIdleCallback()"},{"id":"D","text":"setInterval()"}]', 'B', 'requestAnimationFrame instructs the browser to call a function prior to the next repaint.'),
('q-fe-dom-2', 'cat-fe-dom', 'multiple_choice', 'What metric measures visual stability by tracking unexpected layout shifts during page load?', '[{"id":"A","text":"First Contentful Paint (FCP)"},{"id":"B","text":"Cumulative Layout Shift (CLS)"},{"id":"C","text":"Time to Interactive (TTI)"},{"id":"D","text":"Largest Contentful Paint (LCP)"}]', 'B', 'CLS quantifies how much visible content shifted around in the viewport during load.'),
('q-fe-dom-3', 'cat-fe-dom', 'multiple_choice', 'Which technique delays loading non-critical images until they scroll near the viewport?', '[{"id":"A","text":"Tree shaking"},{"id":"B","text":"Lazy loading"},{"id":"C","text":"Code splitting"},{"id":"D","text":"Debouncing"}]', 'B', 'Lazy loading defers image fetches until required, lowering initial page load payload.'),
('q-fe-dom-4', 'cat-fe-dom', 'yes_no', 'Have you actively audited and eliminated Cumulative Layout Shift (CLS) bottlenecks using browser DevTools Performance panels?', NULL, 'yes', 'Auditing layout shifts guarantees stable user interaction.'),
('q-fe-dom-5', 'cat-fe-dom', 'yes_no', 'Do you implement event debouncing or throttling on search input fields and window scroll listeners to prevent main-thread lag?', NULL, 'yes', 'Debouncing limits function execution frequency during rapid events.');


-- ==================== 2. BACKEND DEVELOPER QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
('q-be-api-1', 'cat-be-api', 'multiple_choice', 'Which HTTP status code should be returned when a POST request successfully creates a new database resource?', '[{"id":"A","text":"200 OK"},{"id":"B","text":"201 Created"},{"id":"C","text":"202 Accepted"},{"id":"D","text":"204 No Content"}]', 'B', '201 Created explicitly indicates that the request succeeded and a new resource was created.'),
('q-be-api-2', 'cat-be-api', 'multiple_choice', 'In Node.js Express, what is the role of the `next()` function inside middleware routines?', '[{"id":"A","text":"Terminates the HTTP request immediately"},{"id":"B","text":"Passes control to the next middleware handler in the stack"},{"id":"C","text":"Restarts the server process"},{"id":"D","text":"Renders a JSON error object"}]', 'B', 'Calling next() invokes the subsequent middleware function in the Express execution pipeline.'),
('q-be-api-3', 'cat-be-api', 'multiple_choice', 'Which HTTP method should be used for idempotent updates that replace the entire resource representation?', '[{"id":"A","text":"POST"},{"id":"B","text":"PUT"},{"id":"C","text":"PATCH"},{"id":"D","text":"DELETE"}]', 'B', 'PUT is idempotent and replaces the target resource entirely with the request payload.'),
('q-be-api-4', 'cat-be-api', 'yes_no', 'Have you configured centralized error handling middleware in Express/Node.js to catch unhandled promise rejections cleanly?', NULL, 'yes', 'Global error middleware prevents server crashes and standardizes HTTP error payloads.'),
('q-be-api-5', 'cat-be-api', 'yes_no', 'Do you enforce strict request payload schema validation (e.g., Zod, Joi) before executing controller business logic?', NULL, 'yes', 'Schema validation blocks malformed request bodies at the routing layer.'),

('q-be-sql-1', 'cat-be-sql', 'multiple_choice', 'Which type of database index is optimal for range queries on ordered data records?', '[{"id":"A","text":"Hash Index"},{"id":"B","text":"B-Tree Index"},{"id":"C","text":"Inverted Index"},{"id":"D","text":"Full-Text Index"}]', 'B', 'B-Tree indexes maintain ordered keys allowing logarithmic lookup and range scans.'),
('q-be-sql-2', 'cat-be-sql', 'multiple_choice', 'What does the "I" (Isolation) in ACID transaction properties guarantee?', '[{"id":"A","text":"Indexes update instantly"},{"id":"B","text":"Concurrent transactions execute without interfering or reading uncommitted data"},{"id":"C","text":"Integrity constraints are bypassed"},{"id":"D","text":"Input parameters are sanitized"}]', 'B', 'Isolation guarantees that concurrent transactions operate as if executed sequentially.'),
('q-be-sql-3', 'cat-be-sql', 'multiple_choice', 'Which SQL clause is used to filter aggregated group results after a `GROUP BY` execution?', '[{"id":"A","text":"WHERE"},{"id":"B","text":"HAVING"},{"id":"C","text":"ORDER BY"},{"id":"D","text":"LIMIT"}]', 'B', 'HAVING filters aggregate values calculated by GROUP BY.'),
('q-be-sql-4', 'cat-be-sql', 'yes_no', 'Do you routinely use database `EXPLAIN` query profilers to identify full table scans and create target indexes?', NULL, 'yes', 'EXPLAIN reveals query execution strategies, helping developers fix slow lookups.'),
('q-be-sql-5', 'cat-be-sql', 'yes_no', 'Have you implemented Redis in-memory caching to cache hot database query reads and reduce database CPU load?', NULL, 'yes', 'Redis caching offloads database queries and improves API response times.'),

('q-be-sec-1', 'cat-be-sec', 'multiple_choice', 'Which cryptographic algorithm is standard and salted for storing user passwords securely?', '[{"id":"A","text":"MD5"},{"id":"B","text":"SHA-1"},{"id":"C","text":"bcrypt"},{"id":"D","text":"Base64"}]', 'C', 'bcrypt is a salted, adaptive hash function designed to withstand brute-force attacks.'),
('q-be-sec-2', 'cat-be-sec', 'multiple_choice', 'Which mechanism prevents unauthorized cross-origin requests from browsers to backend APIs?', '[{"id":"A","text":"CORS (Cross-Origin Resource Sharing)"},{"id":"B","text":"CSRF Tokens"},{"id":"C","text":"SSL Certificates"},{"id":"D","text":"DNS Propagation"}]', 'A', 'CORS headers instruct browsers which origins are allowed to read API responses.'),
('q-be-sec-3', 'cat-be-sec', 'multiple_choice', 'What payload section in a JSON Web Token (JWT) stores claims like user ID and expiration timestamp?', '[{"id":"A","text":"Header"},{"id":"B","text":"Payload"},{"id":"C","text":"Signature"},{"id":"D","text":"Secret Key"}]', 'B', 'The JWT Payload contains user claims and token expiration fields.'),
('q-be-sec-4', 'cat-be-sec', 'yes_no', 'Do you strictly use parameterized queries (prepared statements) to prevent SQL Injection vulnerabilities?', NULL, 'yes', 'Parameterized queries separate SQL commands from user input data.'),
('q-be-sec-5', 'cat-be-sec', 'yes_no', 'Have you set up rate limiting (e.g. express-rate-limit) on authentication endpoints to prevent brute-force attacks?', NULL, 'yes', 'Rate limiting restricts request frequency per IP address to block automated attacks.');


-- ==================== 3. FULLSTACK DEVELOPER QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
('q-fs-web-1', 'cat-fs-web', 'multiple_choice', 'What is the primary advantage of Next.js Server-Side Rendering (SSR) over pure Client-Side Rendering (CSR)?', '[{"id":"A","text":"Smaller server memory footprint"},{"id":"B","text":"Better SEO and faster First Contentful Paint (FCP) by generating HTML on the server"},{"id":"C","text":"Completely eliminates the need for JavaScript"},{"id":"D","text":"Automatic CSS minification"}]', 'B', 'SSR pre-renders HTML per request on the server, improving search engine indexing and initial load speeds.'),
('q-fs-web-2', 'cat-fs-web', 'multiple_choice', 'In a fullstack web application, what is the best practice for storing sensitive API secret keys?', '[{"id":"A","text":"In client-side JavaScript bundle files"},{"id":"B","text":"In environment variables (.env) on the backend server only"},{"id":"C","text":"In public HTML meta tags"},{"id":"D","text":"In LocalStorage"}]', 'B', 'Backend environment variables keep secrets hidden from browser clients.'),
('q-fs-web-3', 'cat-fs-web', 'multiple_choice', 'Which HTTP status code indicates a client is unauthenticated and must log in?', '[{"id":"A","text":"400 Bad Request"},{"id":"B","text":"401 Unauthorized"},{"id":"C","text":"403 Forbidden"},{"id":"D","text":"404 Not Found"}]', 'B', '401 Unauthorized signals missing or invalid authentication credentials.'),
('q-fs-web-4', 'cat-fs-web', 'yes_no', 'Have you designed unified API contracts using TypeScript interfaces shared between frontend and backend repos?', NULL, 'yes', 'Shared TypeScript types guarantee compile-time safety across fullstack boundaries.'),
('q-fs-web-5', 'cat-fs-web', 'yes_no', 'Do you implement automatic JWT token refresh logic when client API requests encounter 401 response codes?', NULL, 'yes', 'Automatic token refresh ensures seamless user session retention.'),

('q-fs-srv-1', 'cat-fs-server', 'multiple_choice', 'Which HTTP header is standard for transmitting JWT Bearer tokens from client to backend APIs?', '[{"id":"A","text":"Content-Type"},{"id":"B","text":"Authorization"},{"id":"C","text":"Accept-Encoding"},{"id":"D","text":"User-Agent"}]', 'B', 'The Authorization header (Authorization: Bearer <token>) carries client credentials securely.'),
('q-fs-srv-2', 'cat-fs-server', 'multiple_choice', 'Which architectural pattern decouples heavy asynchronous tasks (e.g. video processing, email sending) from API response cycles?', '[{"id":"A","text":"Monolithic routing"},{"id":"B","text":"Message Queue / Worker Job System (e.g., BullMQ, RabbitMQ)"},{"id":"C","text":"Synchronous HTTP calls"},{"id":"D","text":"Static page generation"}]', 'B', 'Background message queues execute long-running jobs asynchronously without blocking client responses.'),
('q-fs-srv-3', 'cat-fs-server', 'multiple_choice', 'What is the purpose of HTTP OPTIONS preflight requests sent by browsers in CORS setups?', '[{"id":"A","text":"To download favicons"},{"id":"B","text":"To check with the server if the actual cross-origin request is safe to send"},{"id":"C","text":"To clear browser cache"},{"id":"D","text":"To compress response data"}]', 'B', 'Preflight OPTIONS checks server CORS permissions before sending non-simple HTTP requests.'),
('q-fs-srv-4', 'cat-fs-server', 'yes_no', 'Have you integrated Redis caching layer to reduce heavy database query loads in fullstack web apps?', NULL, 'yes', 'Redis in-memory caching drastically speeds up high-frequency API read operations.'),
('q-fs-srv-5', 'cat-fs-server', 'yes_no', 'Do you deploy backend APIs behind reverse proxies (like Nginx) or process managers (like PM2) for zero-downtime reloads?', NULL, 'yes', 'Reverse proxies and PM2 manage server restarts and load balancing gracefully.'),

('q-fs-orm-1', 'cat-fs-orm', 'multiple_choice', 'In Prisma/TypeORM, what is the main benefit of database migrations?', '[{"id":"A","text":"Automatically design UI pages"},{"id":"B","text":"Version-control database schema changes and execute them predictably across environments"},{"id":"C","text":"Encrypt user passwords automatically"},{"id":"D","text":"Compress database disk storage"}]', 'B', 'Migrations provide trackable, repeatable schema evolutions across staging and production.'),
('q-fs-orm-2', 'cat-fs-orm', 'multiple_choice', 'What database issue occurs when an ORM executes 1 initial query followed by N separate queries for child relationships?', '[{"id":"A","text":"Dirty Read Problem"},{"id":"B","text":"N+1 Query Problem"},{"id":"C","text":"Deadlock"},{"id":"D","text":"Index Scanning"}]', 'B', 'The N+1 problem causes severe latency by making individual database queries for each relation item.'),
('q-fs-orm-3', 'cat-fs-orm', 'multiple_choice', 'Which database join type returns all records from the left table and matched records from the right table?', '[{"id":"A","text":"INNER JOIN"},{"id":"B","text":"LEFT JOIN"},{"id":"C","text":"RIGHT JOIN"},{"id":"D","text":"FULL OUTER JOIN"}]', 'B', 'LEFT JOIN retains all rows from the left table regardless of right table matches.'),
('q-fs-orm-4', 'cat-fs-orm', 'yes_no', 'Do you manage database foreign key constraints and cascading deletes in ORM schemas to prevent orphaned data records?', NULL, 'yes', 'Relational integrity constraints enforce consistent database states.'),
('q-fs-orm-5', 'cat-fs-orm', 'yes_no', 'Have you used database seeders to populate initial lookup tables and test fixtures across development environments?', NULL, 'yes', 'Database seeders automate consistent test data setup.');


-- ==================== 4. DATA SCIENTIST QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
('q-ds-py-1', 'cat-ds-python', 'multiple_choice', 'In Python Pandas, which method is used to aggregate data by categories and compute metrics like mean or count?', '[{"id":"A","text":"df.pivot()"},{"id":"B","text":"df.groupby()"},{"id":"C","text":"df.sort_values()"},{"id":"D","text":"df.concat()"}]', 'B', 'groupby() splits data into groups, applies aggregation functions, and combines results.'),
('q-ds-py-2', 'cat-ds-python', 'multiple_choice', 'Which technique transforms categorical text columns into numerical binary flags for ML model input?', '[{"id":"A","text":"Min-Max Scaling"},{"id":"B","text":"One-Hot Encoding"},{"id":"C","text":"Log Transformation"},{"id":"D","text":"Z-Score Normalization"}]', 'B', 'One-Hot Encoding converts categorical variables into multi-column binary features.'),
('q-ds-py-3', 'cat-ds-python', 'multiple_choice', 'Which Python scientific library provides optimized C-backed array processing and vectorization capabilities?', '[{"id":"A","text":"Pandas"},{"id":"B","text":"NumPy"},{"id":"C","text":"Requests"},{"id":"D","text":"Flask"}]', 'B', 'NumPy is the core library for high-performance numerical array operations.'),
('q-ds-py-4', 'cat-ds-python', 'yes_no', 'Do you routinely handle missing dataset values using strategic KNN or median/mode imputation before modeling?', NULL, 'yes', 'Imputation retains dataset samples and prevents bias in machine learning models.'),
('q-ds-py-5', 'cat-ds-python', 'yes_no', 'Have you used vectorization instead of Python `for` loops when manipulating large Pandas DataFrames?', NULL, 'yes', 'Vectorized operations execute C-level loops, running up to 100x faster.'),

('q-ds-ml-1', 'cat-ds-ml', 'multiple_choice', 'What metric is most appropriate for evaluating a binary classification model on an imbalanced dataset?', '[{"id":"A","text":"Accuracy"},{"id":"B","text":"F1-Score / ROC-AUC"},{"id":"C","text":"Mean Squared Error"},{"id":"D","text":"R-Squared"}]', 'B', 'F1-Score and ROC-AUC measure precision/recall trade-offs effectively on imbalanced data.'),
('q-ds-ml-2', 'cat-ds-ml', 'multiple_choice', 'What occurs when a machine learning model fits training data noise perfectly, failing to generalize to unseen test data?', '[{"id":"A","text":"Underfitting"},{"id":"B","text":"Overfitting"},{"id":"C","text":"Covariate Shift"},{"id":"D","text":"Standardization"}]', 'B', 'Overfitting happens when excessive model complexity memorizes training noise.'),
('q-ds-ml-3', 'cat-ds-ml', 'multiple_choice', 'Which algorithm is an unsupervised learning technique used for customer segmentation and clustering?', '[{"id":"A","text":"Linear Regression"},{"id":"B","text":"K-Means Clustering"},{"id":"C","text":"Logistic Regression"},{"id":"D","text":"Random Forest Classifier"}]', 'B', 'K-Means partitions data into K clusters based on distance centroids.'),
('q-ds-ml-4', 'cat-ds-ml', 'yes_no', 'Do you implement K-Fold Cross-Validation to validate model hyperparameter tuning objectively?', NULL, 'yes', 'K-Fold CV prevents overfitting by testing models across multiple out-of-fold subsets.'),
('q-ds-ml-5', 'cat-ds-ml', 'yes_no', 'Have you deployed machine learning models as HTTP API endpoints using tools like FastAPI or Flask?', NULL, 'yes', 'API endpoints allow web/mobile applications to fetch live model predictions.'),

('q-ds-pipe-1', 'cat-ds-pipe', 'multiple_choice', 'In SQL data engineering, which window function calculates the rank of a row within a result partition?', '[{"id":"A","text":"ROW_NUMBER() / DENSE_RANK()"},{"id":"B","text":"COUNT()"},{"id":"C","text":"SUM()"},{"id":"D","text":"COALESCE()"}]', 'A', 'Window functions like ROW_NUMBER() evaluate relative row positions across dataset partitions.'),
('q-ds-pipe-2', 'cat-ds-pipe', 'multiple_choice', 'What is the primary objective of Feature Engineering in data science pipelines?', '[{"id":"A","text":"To write documentation for databases"},{"id":"B","text":"To create new informative features from raw data to improve model predictive accuracy"},{"id":"C","text":"To reduce server memory usage"},{"id":"D","text":"To format HTML tables"}]', 'B', 'Feature engineering extracts domain insights into numerical inputs for algorithms.'),
('q-ds-pipe-3', 'cat-ds-pipe', 'multiple_choice', 'Which data format is columnar and optimized for big data analytics queries in systems like Apache Spark?', '[{"id":"A","text":"JSON"},{"id":"B","text":"Parquet"},{"id":"C","text":"CSV"},{"id":"D","text":"TXT"}]', 'B', 'Parquet is a compressed, columnar storage format optimized for high-speed analytical queries.'),
('q-ds-pipe-4', 'cat-ds-pipe', 'yes_no', 'Do you build automated ETL (Extract, Transform, Load) pipelines to ingest and clean raw data sources periodically?', NULL, 'yes', 'Automated ETL pipelines transform raw logs into structured analytics tables.'),
('q-ds-pipe-5', 'cat-ds-pipe', 'yes_no', 'Have you tracked experiment metrics and model versioning artifacts using tools like MLflow or Weights & Biases?', NULL, 'yes', 'Experiment tracking tools ensure reproducibility of machine learning models.');


-- ==================== 5. UI/UX DESIGNER QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
('q-ux-fig-1', 'cat-ux-figma', 'multiple_choice', 'In Figma, what is the primary benefit of using Auto Layout on UI components?', '[{"id":"A","text":"Automatically generates production React code"},{"id":"B","text":"Creates responsive containers that resize dynamically according to padding, alignment, and content text"},{"id":"C","text":"Compresses image asset export sizes"},{"id":"D","text":"Locks layers from being edited by team members"}]', 'B', 'Auto Layout builds adaptive frames that reflow dynamically when text or content changes.'),
('q-ux-fig-2', 'cat-ux-figma', 'multiple_choice', 'What are Design Tokens in modern Figma and UI Design Systems?', '[{"id":"A","text":"Cryptocurrency tokens used to pay designers"},{"id":"B","text":"Centralized design variables (colors, spacing, typography, elevation) shared between design tools and codebases"},{"id":"C","text":"Plugins for exporting PDF mockups"},{"id":"D","text":"Vector icon sets"}]', 'B', 'Design tokens store design values centrally, synchronizing design specs with frontend code.'),
('q-ux-fig-3', 'cat-ux-figma', 'multiple_choice', 'In Figma, what feature allows designers to create interactive state transitions (hover, pressed, active) on a single master component?', '[{"id":"A","text":"Component Variants"},{"id":"B","text":"Vector Networks"},{"id":"C","text":"Masking Groups"},{"id":"D","text":"Smart Animate Layers"}]', 'A', 'Component Variants group related component states into a single editable UI asset.'),
('q-ux-fig-4', 'cat-ux-figma', 'yes_no', 'Do you construct reusable Figma Component Sets with Component Properties (variants, booleans, text instances) for design systems?', NULL, 'yes', 'Figma component variants streamline UI design updates and component consistency.'),
('q-ux-fig-5', 'cat-ux-figma', 'yes_no', 'Have you created interactive Figma prototypes using Smart Animate to demonstrate micro-interactions to developers?', NULL, 'yes', 'Interactive prototypes communicate motion design and micro-interactions clearly.'),

('q-ux-heu-1', 'cat-ux-heuristics', 'multiple_choice', 'According to Jakob Nielsen 10 Usability Heuristics, what does "Visibility of System Status" mean?', '[{"id":"A","text":"Making all system source code public"},{"id":"B","text":"Keeping users informed about what is happening through appropriate feedback within reasonable time"},{"id":"C","text":"Showing full dark mode options"},{"id":"D","text":"Displaying detailed database IDs on screen"}]', 'B', 'System status visibility ensures users receive prompt, clear feedback (e.g. loading indicators, status toasts).'),
('q-ux-heu-2', 'cat-ux-heuristics', 'multiple_choice', 'What is Fitts Law in User Interface & Interaction Design?', '[{"id":"A","text":"The time to acquire a target is a function of the distance to and size of the target"},{"id":"B","text":"Users spend most of their time on other sites"},{"id":"C","text":"Page load speed must be under 2 seconds"},{"id":"D","text":"Color contrast must be 4.5:1"}]', 'A', 'Fitts Law states that larger, closer touch/click targets are faster and easier for users to hit.'),
('q-ux-heu-3', 'cat-ux-heuristics', 'multiple_choice', 'What is Miller Law regarding human working memory in UX design?', '[{"id":"A","text":"An average person can only keep 7 (plus or minus 2) items in their working memory"},{"id":"B","text":"Users scroll vertically 80% of the time"},{"id":"C","text":"Buttons must be blue"},{"id":"D","text":"Form fields should have 3 steps"}]', 'A', 'Millers Law emphasizes chunking information into groups of 5-9 items to prevent cognitive overload.'),
('q-ux-heu-4', 'cat-ux-heuristics', 'yes_no', 'Do you conduct WCAG color contrast checks on text and interactive buttons during high-fidelity mockup creation?', NULL, 'yes', 'WCAG contrast validation guarantees accessible design for users with visual impairments.'),
('q-ux-heu-5', 'cat-ux-heuristics', 'yes_no', 'Have you conducted Heuristic Evaluations on existing UI products to identify usability flaws against Nielsen guidelines?', NULL, 'yes', 'Heuristic evaluations systematically audit UI designs for usability issues.'),

('q-ux-res-1', 'cat-ux-research', 'multiple_choice', 'What is the main goal of creating low-fidelity wireframes before high-fidelity visual design?', '[{"id":"A","text":"To test final color schemes and typography"},{"id":"B","text":"To quickly iterate on layout structure, user flows, and content hierarchy without getting distracted by visual polish"},{"id":"C","text":"To generate final SVG image assets"},{"id":"D","text":"To test database load speeds"}]', 'B', 'Low-fi wireframes focus design validation on structural UX flow and navigation hierarchy.'),
('q-ux-res-2', 'cat-ux-research', 'multiple_choice', 'Which user research artifact synthesizes qualitative interview findings into a fictional representation of a target user group?', '[{"id":"A","text":"User Persona"},{"id":"B","text":"System Architecture Diagram"},{"id":"C","text":"Database Schema"},{"id":"D","text":"Sprint Backlog"}]', 'A', 'User Personas summarize user goals, pain points, and behaviors to guide design decisions.'),
('q-ux-res-3', 'cat-ux-research', 'multiple_choice', 'What research method presents users with 2 variations of a screen (A and B) to measure performance differences?', '[{"id":"A","text":"Tree Testing"},{"id":"B","text":"A/B Testing"},{"id":"C","text":"Card Sorting"},{"id":"D","text":"Contextual Inquiry"}]', 'B', 'A/B testing evaluates live performance metrics between 2 design variants.'),
('q-ux-res-4', 'cat-ux-research', 'yes_no', 'Have you actively conducted usability testing sessions with real users using interactive prototypes to validate UX flows?', NULL, 'yes', 'Usability testing uncovers user friction and interaction flaws early in the design cycle.'),
('q-ux-res-5', 'cat-ux-research', 'yes_no', 'Do you create User Journey Maps to visualize customer touchpoints, emotions, and pain points across product flows?', NULL, 'yes', 'Journey mapping aligns product teams around end-to-end user experiences.');


-- ==================== 6. MOBILE DEVELOPER QUESTIONS ====================
INSERT IGNORE INTO assessment_questions (id, category_id, question_type, question_text, options, correct_answer, explanation) VALUES
-- mb_flutter_dart
('q-mb-fl-1', 'cat-mb-flutter', 'multiple_choice', 'In Flutter, what is the fundamental difference between a StatelessWidget and a StatefulWidget?', '[{"id":"A","text":"StatelessWidget cannot display images"},{"id":"B","text":"StatefulWidget maintains mutable state that can trigger rebuilds via `setState()`"},{"id":"C","text":"StatelessWidget runs only on Android"},{"id":"D","text":"StatefulWidget cannot accept constructor parameters"}]', 'B', 'StatefulWidget holds a State object that can mutate and trigger UI rebuilds when state changes.'),
('q-mb-fl-2', 'cat-mb-flutter', 'multiple_choice', 'Which Widget in Flutter is used to build efficient scrolling lists with lazy rendering for hundreds of items?', '[{"id":"A","text":"Column"},{"id":"B","text":"SingleChildScrollView"},{"id":"C","text":"ListView.builder"},{"id":"D","text":"Stack"}]', 'C', 'ListView.builder creates list items lazily only when they are scrolled into the screen viewport.'),
('q-mb-fl-3', 'cat-mb-flutter', 'multiple_choice', 'In Dart, which keyword is used to declare a variable that will be initialized once at runtime before being accessed?', '[{"id":"A","text":"const"},{"id":"B","text":"late"},{"id":"C","text":"dynamic"},{"id":"D","text":"static"}]', 'B', 'The `late` keyword explicitly marks a non-nullable variable for deferred runtime initialization.'),
('q-mb-fl-4', 'cat-mb-flutter', 'yes_no', 'Do you use `const` constructors on Flutter widgets wherever possible to optimize widget tree rebuild performance?', NULL, 'yes', 'Using const widgets prevents Flutter from unnecessarily re-instantiating unchanged widget subtrees.'),
('q-mb-fl-5', 'cat-mb-flutter', 'yes_no', 'Have you written custom Flutter CustomPainter or animation controllers for dynamic UI motion?', NULL, 'yes', 'CustomPainter and AnimationController allow rich native 60fps canvas graphics.'),

-- mb_crossplatform_state
('q-mb-st-1', 'cat-mb-state', 'multiple_choice', 'In Riverpod / Bloc state management, why is immutable state management preferred over direct object mutation?', '[{"id":"A","text":"It reduces file size on disk"},{"id":"B","text":"It ensures predictable state changes, easy state comparison, and reliable UI reactive listener triggers"},{"id":"C","text":"It bypasses Dart compilation"},{"id":"D","text":"It allows instant SQL execution"}]', 'B', 'Immutable state objects guarantee predictable state transitions and prevent unexpected side effects.'),
('q-mb-st-2', 'cat-mb-state', 'multiple_choice', 'Which package in Flutter is standard for declarative, type-safe route navigation supporting web deep-linking and nested shells?', '[{"id":"A","text":"Navigator 1.0"},{"id":"B","text":"Go Router"},{"id":"C","text":"HTTP Package"},{"id":"D","text":"SharedPreferences"}]', 'B', 'Go Router provides declarative routing matching URLs to Flutter screens smoothly across mobile and web.'),
('q-mb-st-3', 'cat-mb-state', 'multiple_choice', 'In Flutter Riverpod, which provider type is specifically optimized for managing complex asynchronous state (like API calls)?', '[{"id":"A","text":"StateProvider"},{"id":"B","text":"AsyncNotifierProvider / FutureProvider"},{"id":"C","text":"Provider"},{"id":"D","text":"StreamProvider"}]', 'B', 'AsyncNotifierProvider manages asynchronous state transitions (loading, data, error) automatically.'),
('q-mb-st-4', 'cat-mb-state', 'yes_no', 'Do you separate UI presentation code cleanly from business logic using state management patterns (Riverpod, BLoC, Provider)?', NULL, 'yes', 'Decoupling business logic from UI widgets ensures testability and clean architecture.'),
('q-mb-st-5', 'cat-mb-state', 'yes_no', 'Have you implemented app lifecycle state observers (AppLifecycleState) to pause or resume socket connections when backgrounded?', NULL, 'yes', 'Lifecycle observers prevent battery drain and manage background state transitions.'),

-- mb_native_api_storage
('q-mb-nat-1', 'cat-mb-native', 'multiple_choice', 'Which lightweight key-value local storage engine is popular in Flutter for fast synchronous offline data persistence?', '[{"id":"A","text":"Hive / Isar"},{"id":"B","text":"MySQL Server"},{"id":"C","text":"MongoDB"},{"id":"D","text":"Redis"}]', 'A', 'Hive/Isar are fast, pure-Dart key-value and NoSQL database engines optimized for mobile apps.'),
('q-mb-nat-2', 'cat-mb-native', 'multiple_choice', 'Which mechanism allows Flutter Dart code to communicate directly with native iOS (Swift) and Android (Kotlin) platform APIs?', '[{"id":"A","text":"Platform Channels (MethodChannel)"},{"id":"B","text":"HTTP REST API"},{"id":"C","text":"WebSockets"},{"id":"D","text":"Shared Preferences"}]', 'A', 'MethodChannel passes messages between Dart code and host native platform code.'),
('q-mb-nat-3', 'cat-mb-native', 'multiple_choice', 'What plugin is standard in Flutter for handling push notifications across iOS and Android?', '[{"id":"A","text":"flutter_local_notifications / Firebase Messaging"},{"id":"B","text":"path_provider"},{"id":"C","text":"image_picker"},{"id":"D","text":"sqflite"}]', 'A', 'Firebase Cloud Messaging & flutter_local_notifications manage background/foreground push alerts.'),
('q-mb-nat-4', 'cat-mb-native', 'yes_no', 'Have you configured mobile native permissions (camera, location, photo gallery) in AndroidManifest.xml and iOS Info.plist files?', NULL, 'yes', 'Native permissions must be declared in platform configuration files for runtime access.'),
('q-mb-nat-5', 'cat-mb-native', 'yes_no', 'Have you configured local SQLite/Hive caching to allow mobile apps to operate seamlessly on spotty networks?', NULL, 'yes', 'Local database caching ensures offline availability on unreliable networks.');

-- ==================== 4. SEED MINI PROJECTS & ROLE MAPPING ====================

-- 4.1 Mini Projects Seed (3 Projects Per Role = 18 Dedicated Mini Projects)
INSERT IGNORE INTO mini_projects (id, title, description, difficulty, estimated_hours, points, tech_stack, tasks, sort_order) VALUES
-- Frontend Developer Mini Projects
('mp-fe-1', 'React E-Commerce Dashboard', 'Build a dynamic, responsive e-commerce management dashboard using React, Tailwind CSS, and custom hooks.', 'Intermediate', 6, 150, '["React", "Tailwind CSS", "TypeScript"]', '["Create responsive layout grid", "Implement dark mode theme switcher", "Build filterable product data table"]', 1),
('mp-fe-2', 'Web Performance & CLS Optimization', 'Audit and fix performance bottlenecks in a heavy web page, optimizing Largest Contentful Paint (LCP) and eliminating Cumulative Layout Shift (CLS).', 'Advanced', 5, 200, '["Lighthouse", "JavaScript", "Webpack"]', '["Lazy load below-the-fold images", "Implement font display swap", "Eliminate render-blocking CSS resources"]', 2),
('mp-fe-3', 'State Management SPA with Zustand', 'Develop a single-page application incorporating complex client-side state management, async persistence, and undo/redo history.', 'Intermediate', 4, 120, '["React", "Zustand", "REST API"]', '["Setup central Zustand store", "Add persistent state storage", "Implement undo/redo action stack"]', 3),

-- Backend Developer Mini Projects
('mp-be-1', 'Express REST API with JWT Auth', 'Design and deploy a secure Node.js Express REST API featuring bcrypt password hashing, JWT stateless authentication, and input validation.', 'Intermediate', 6, 150, '["Node.js", "Express", "JWT", "bcrypt"]', '["Set up auth registration and login endpoints", "Implement JWT token validation middleware", "Add Zod schema request validation"]', 1),
('mp-be-2', 'Database Query Optimization Lab', 'Optimize slow relational database queries using B-Tree indexing, EXPLAIN execution plan analysis, and connection pooling.', 'Advanced', 5, 200, '["MySQL", "Node.js", "EXPLAIN"]', '["Identify full table scan queries using EXPLAIN", "Create compound B-Tree indexes on join foreign keys", "Refactor N+1 queries into single JOINs"]', 2),
('mp-be-3', 'Redis Rate Limiter & Caching Gateway', 'Implement an in-memory Redis caching gateway and IP-based rate limiter middleware to protect backend services from traffic spikes.', 'Intermediate', 4, 120, '["Node.js", "Redis", "Express"]', '["Configure Redis connection client", "Implement sliding-window IP rate limiter middleware", "Cache high-frequency GET endpoint responses"]', 3),

-- Fullstack Developer Mini Projects
('mp-fs-1', 'Next.js Fullstack Platform', 'Develop a fullstack web platform utilizing Next.js Server-Side Rendering (SSR), Server Actions, Prisma ORM, and relational MySQL database.', 'Advanced', 8, 250, '["Next.js", "Prisma", "TypeScript", "MySQL"]', '["Build SSR product catalog pages", "Set up Prisma ORM database models and migrations", "Implement Server Actions for user submissions"]', 1),
('mp-fs-2', 'Fullstack API Contract System', 'Construct a fullstack web app featuring a shared TypeScript contract package enforcing compile-time payload safety across client and server.', 'Intermediate', 5, 160, '["TypeScript", "React", "Express"]', '["Create shared DTO interface library", "Wire client HTTP fetcher to typed API endpoints", "Implement unified error handling contract"]', 2),
('mp-fs-3', 'Background Job Queue Worker', 'Set up an asynchronous worker queue (BullMQ + Redis) to process background tasks (email sending, image processing) out of the main HTTP thread.', 'Advanced', 6, 200, '["Node.js", "BullMQ", "Redis"]', '["Create Redis-backed queue producer", "Build worker process to consume async tasks", "Implement retry logic and dead-letter queues"]', 3),

-- Data Scientist Mini Projects
('mp-ds-1', 'Pandas Data Cleaning & Exploratory Pipeline', 'Clean a messy real-world CSV dataset, perform feature encoding, handle missing values, and generate summary statistical distributions.', 'Intermediate', 5, 140, '["Python", "Pandas", "NumPy", "Seaborn"]', '["Perform KNN imputation on missing numerical data", "Apply One-Hot Encoding to categorical columns", "Generate feature correlation heatmap"]', 1),
('mp-ds-2', 'Customer Churn Machine Learning Classifier', 'Train, evaluate, and tune a Random Forest classifier to predict customer churn, measuring performance via F1-Score and ROC-AUC metrics.', 'Advanced', 7, 220, '["Python", "Scikit-Learn", "Jupyter"]', '["Preprocess data and split into train/test sets", "Train Random Forest Classifier with K-Fold CV", "Evaluate ROC-AUC curve and confusion matrix"]', 2),
('mp-ds-3', 'Automated Data ETL Pipeline', 'Design an automated Python ETL pipeline that extracts raw JSON logs, transforms features, and writes cleaned analytical tables into SQL.', 'Advanced', 6, 180, '["Python", "SQL", "ETL Pipelines"]', '["Ingest multi-source JSON payloads", "Execute feature transformations and window aggregations", "Load cleaned dataset into MySQL analytical tables"]', 3),

-- UI/UX Designer Mini Projects
('mp-ux-1', 'Figma Design System & Auto Layout Library', 'Construct a scalable, responsive Figma design system incorporating Auto Layout, color design tokens, and interactive component variants.', 'Intermediate', 6, 160, '["Figma", "Design Systems", "Auto Layout"]', '["Create color and typography design token styles", "Build flexible Auto Layout button and card components", "Set up interactive component state variants (hover, active)"]', 1),
('mp-ux-2', 'Mobile Usability Audit & Redesign', 'Perform a Nielsen Heuristic Usability Audit on a mobile app flow, identify accessibility friction points, and deliver a high-fi interactive prototype.', 'Intermediate', 5, 150, '["Figma", "Usability Testing", "WCAG"]', '["Document usability flaws using Nielsen 10 Heuristics", "Audit color contrast ratios against WCAG 2.1 AA standards", "Build interactive high-fidelity Figma prototype"]', 2),
('mp-ux-3', 'User Research & Wireframing Flow', 'Conduct user interviews, construct target User Personas and Journey Maps, and map out low-fidelity wireframe user navigation flows.', 'Intermediate', 4, 130, '["User Research", "Wireframing", "Figma"]', '["Synthesize qualitative interview data into Personas", "Map out end-to-end User Journey Map", "Design low-fidelity wireframe navigation flows"]', 3),

-- Mobile Developer Mini Projects
('mp-mb-1', 'Flutter Multi-Tab App with Riverpod', 'Develop a multi-tab mobile application using Flutter, declarative Go Router navigation, and Riverpod reactive state management.', 'Intermediate', 6, 160, '["Flutter", "Dart", "Riverpod", "Go Router"]', '["Create responsive multi-tab shell navigation", "Implement Riverpod AsyncNotifier for state management", "Design responsive mobile layout screens"]', 1),
('mp-mb-2', 'Offline-First Local Storage App', 'Build a Flutter mobile app that operates seamlessly offline using Hive / Isar local database caching and network connectivity listeners.', 'Advanced', 6, 180, '["Flutter", "Hive", "Isar", "Offline Sync"]', '["Set up Hive key-value local storage box", "Implement network status listener for offline mode", "Sync local offline edits to server upon reconnect"]', 2),
('mp-mb-3', 'Native MethodChannel & Camera Integration', 'Develop a Flutter app incorporating native device camera plugins, local photo storage, and platform channels for device status.', 'Advanced', 5, 170, '["Flutter", "MethodChannel", "Camera Plugin"]', '["Configure Android and iOS native permissions", "Implement Flutter Camera plugin preview and capture", "Write native MethodChannel bridge for battery status"]', 3);

-- 4.2 Role Mini Project Mapping (Strictly 3 Projects Per Role)
INSERT IGNORE INTO mini_project_role_mapping (id, mini_project_id, target_role_pattern, priority) VALUES
-- Frontend Developer Projects (3)
('mpr-fe-1', 'mp-fe-1', 'Frontend Developer', 1),
('mpr-fe-2', 'mp-fe-2', 'Frontend Developer', 2),
('mpr-fe-3', 'mp-fe-3', 'Frontend Developer', 3),

-- Backend Developer Projects (3)
('mpr-be-1', 'mp-be-1', 'Backend Developer', 1),
('mpr-be-2', 'mp-be-2', 'Backend Developer', 2),
('mpr-be-3', 'mp-be-3', 'Backend Developer', 3),

-- Fullstack Developer Projects (3)
('mpr-fs-1', 'mp-fs-1', 'Fullstack Developer', 1),
('mpr-fs-2', 'mp-fs-2', 'Fullstack Developer', 2),
('mpr-fs-3', 'mp-fs-3', 'Fullstack Developer', 3),

-- Data Scientist Projects (3)
('mpr-ds-1', 'mp-ds-1', 'Data Scientist', 1),
('mpr-ds-2', 'mp-ds-2', 'Data Scientist', 2),
('mpr-ds-3', 'mp-ds-3', 'Data Scientist', 3),

-- UI/UX Designer Projects (3)
('mpr-ux-1', 'mp-ux-1', 'UI/UX Designer', 1),
('mpr-ux-2', 'mp-ux-2', 'UI/UX Designer', 2),
('mpr-ux-3', 'mp-ux-3', 'UI/UX Designer', 3),

-- Mobile Developer Projects (3)
('mpr-mb-1', 'mp-mb-1', 'Mobile Developer', 1),
('mpr-mb-2', 'mp-mb-2', 'Mobile Developer', 2),
('mpr-mb-3', 'mp-mb-3', 'Mobile Developer', 3);

-- ==========================================
-- END OF INITIALIZATION SQL
-- ==========================================
