/*
  Novagril Board — SQL Server schema
  Safe to review before applying to the existing hosting database.
  No secrets are stored here.
*/

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.nb_users','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_users (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_users PRIMARY KEY DEFAULT NEWID(),
    email NVARCHAR(320) NOT NULL,
    display_name NVARCHAR(160) NOT NULL,
    role NVARCHAR(20) NOT NULL CONSTRAINT DF_nb_users_role DEFAULT 'member',
    status NVARCHAR(20) NOT NULL CONSTRAINT DF_nb_users_status DEFAULT 'invited',
    entra_tenant_id UNIQUEIDENTIFIER NULL,
    entra_object_id UNIQUEIDENTIFIER NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_users_created DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_users_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_nb_users_email UNIQUE(email),
    CONSTRAINT CK_nb_users_role CHECK (role IN ('admin','member')),
    CONSTRAINT CK_nb_users_status CHECK (status IN ('invited','active','revoked'))
  );

  CREATE UNIQUE INDEX UX_nb_users_entra
    ON dbo.nb_users(entra_tenant_id, entra_object_id)
    WHERE entra_tenant_id IS NOT NULL AND entra_object_id IS NOT NULL;
END;

IF OBJECT_ID('dbo.nb_invitations','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_invitations (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_invitations PRIMARY KEY DEFAULT NEWID(),
    user_id UNIQUEIDENTIFIER NOT NULL,
    token_hash VARBINARY(64) NOT NULL,
    expires_at DATETIME2(0) NOT NULL,
    accepted_at DATETIME2(0) NULL,
    revoked_at DATETIME2(0) NULL,
    delivery_status NVARCHAR(20) NOT NULL CONSTRAINT DF_nb_inv_delivery DEFAULT 'pending',
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_inv_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_nb_inv_user FOREIGN KEY(user_id) REFERENCES dbo.nb_users(id),
    CONSTRAINT UQ_nb_inv_token UNIQUE(token_hash)
  );
END;

IF OBJECT_ID('dbo.nb_auth_pins','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_auth_pins (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_auth_pins PRIMARY KEY DEFAULT NEWID(),
    email NVARCHAR(320) NOT NULL,
    pin_hash VARBINARY(64) NOT NULL,
    attempts TINYINT NOT NULL CONSTRAINT DF_nb_pin_attempts DEFAULT 0,
    expires_at DATETIME2(0) NOT NULL,
    used_at DATETIME2(0) NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_pin_created DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_nb_auth_pins_email ON dbo.nb_auth_pins(email, expires_at);
END;

IF OBJECT_ID('dbo.nb_sessions','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_sessions (
    token_hash VARBINARY(64) NOT NULL CONSTRAINT PK_nb_sessions PRIMARY KEY,
    user_id UNIQUEIDENTIFIER NOT NULL,
    csrf_token NVARCHAR(128) NOT NULL,
    auth_method NVARCHAR(20) NOT NULL,
    expires_at DATETIME2(0) NOT NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_sessions_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_nb_sessions_user FOREIGN KEY(user_id) REFERENCES dbo.nb_users(id),
    CONSTRAINT CK_nb_sessions_method CHECK(auth_method IN ('pin','microsoft'))
  );
  CREATE INDEX IX_nb_sessions_user ON dbo.nb_sessions(user_id, expires_at);
END;

IF OBJECT_ID('dbo.nb_departments','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_departments (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_departments PRIMARY KEY DEFAULT NEWID(),
    slug NVARCHAR(80) NOT NULL,
    name NVARCHAR(160) NOT NULL,
    color CHAR(7) NOT NULL,
    sort_order INT NOT NULL CONSTRAINT DF_nb_departments_sort DEFAULT 0,
    is_active BIT NOT NULL CONSTRAINT DF_nb_departments_active DEFAULT 1,
    created_by_user_id UNIQUEIDENTIFIER NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_departments_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_nb_departments_slug UNIQUE(slug),
    CONSTRAINT FK_nb_departments_creator FOREIGN KEY(created_by_user_id) REFERENCES dbo.nb_users(id)
  );
END;

IF OBJECT_ID('dbo.nb_projects','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_projects (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_projects PRIMARY KEY DEFAULT NEWID(),
    title NVARCHAR(180) NOT NULL,
    short_description NVARCHAR(700) NULL,
    department_id UNIQUEIDENTIFIER NULL,
    priority_level TINYINT NULL,
    ring_position DECIMAL(8,5) NULL,
    status NVARCHAR(20) NOT NULL CONSTRAINT DF_nb_projects_status DEFAULT 'proposed',
    created_by_user_id UNIQUEIDENTIFIER NOT NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_projects_created DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_projects_updated DEFAULT SYSUTCDATETIME(),
    row_version ROWVERSION NOT NULL,
    CONSTRAINT FK_nb_projects_department FOREIGN KEY(department_id) REFERENCES dbo.nb_departments(id),
    CONSTRAINT FK_nb_projects_creator FOREIGN KEY(created_by_user_id) REFERENCES dbo.nb_users(id),
    CONSTRAINT CK_nb_projects_priority CHECK(priority_level IS NULL OR priority_level BETWEEN 1 AND 4),
    CONSTRAINT CK_nb_projects_status CHECK(status IN ('proposed','analysis','active','archived')),
    CONSTRAINT CK_nb_projects_position CHECK(ring_position IS NULL OR (ring_position >= 0 AND ring_position <= 1))
  );
  CREATE INDEX IX_nb_projects_map ON dbo.nb_projects(department_id, priority_level, ring_position);
  CREATE INDEX IX_nb_projects_creator ON dbo.nb_projects(created_by_user_id);
END;

IF OBJECT_ID('dbo.nb_votes','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_votes (
    project_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    vote_value TINYINT NOT NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_votes_created DEFAULT SYSUTCDATETIME(),
    updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_votes_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_nb_votes PRIMARY KEY(project_id,user_id),
    CONSTRAINT FK_nb_votes_project FOREIGN KEY(project_id) REFERENCES dbo.nb_projects(id) ON DELETE CASCADE,
    CONSTRAINT FK_nb_votes_user FOREIGN KEY(user_id) REFERENCES dbo.nb_users(id),
    CONSTRAINT CK_nb_votes_value CHECK(vote_value BETWEEN 0 AND 100)
  );
END;

IF OBJECT_ID('dbo.nb_comments','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_comments (
    id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_nb_comments PRIMARY KEY DEFAULT NEWID(),
    project_id UNIQUEIDENTIFIER NOT NULL,
    user_id UNIQUEIDENTIFIER NOT NULL,
    body NVARCHAR(1500) NOT NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_comments_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_nb_comments_project FOREIGN KEY(project_id) REFERENCES dbo.nb_projects(id) ON DELETE CASCADE,
    CONSTRAINT FK_nb_comments_user FOREIGN KEY(user_id) REFERENCES dbo.nb_users(id)
  );
END;

IF OBJECT_ID('dbo.nb_activities','U') IS NULL
BEGIN
  CREATE TABLE dbo.nb_activities (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_nb_activities PRIMARY KEY,
    actor_user_id UNIQUEIDENTIFIER NULL,
    action NVARCHAR(80) NOT NULL,
    entity_type NVARCHAR(40) NOT NULL,
    entity_id UNIQUEIDENTIFIER NULL,
    payload_json NVARCHAR(MAX) NULL,
    created_at DATETIME2(0) NOT NULL CONSTRAINT DF_nb_activities_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_nb_activities_actor FOREIGN KEY(actor_user_id) REFERENCES dbo.nb_users(id),
    CONSTRAINT CK_nb_activities_json CHECK(payload_json IS NULL OR ISJSON(payload_json)=1)
  );
  CREATE INDEX IX_nb_activities_created ON dbo.nb_activities(created_at DESC);
END;

-- Initial departments. Re-runnable.
DECLARE @Departments TABLE(slug NVARCHAR(80), name NVARCHAR(160), color CHAR(7), sort_order INT);
INSERT INTO @Departments VALUES
('vendas','Vendas','#55BA47',10),
('tecnica','Técnica','#7AC943',20),
('logistica','Logística','#F09A3E',30),
('calisflor','Calisflor','#E04B9A',40),
('academia','Academia','#8D5CE6',50),
('administracao','Administração','#428CCB',60),
('financeira-administrativa','Financeira e Administrativa','#20B8B2',70),
('contabilidade','Contabilidade','#D9A441',80),
('retalho','Retalho','#D94B9B',90),
('rh','RH','#3C9DEB',100);

INSERT INTO dbo.nb_departments(slug,name,color,sort_order)
SELECT d.slug,d.name,d.color,d.sort_order
FROM @Departments d
WHERE NOT EXISTS (SELECT 1 FROM dbo.nb_departments x WHERE x.slug=d.slug);

COMMIT TRANSACTION;
