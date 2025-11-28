-- CreateTable
CREATE TABLE "logs" (
    "id" SERIAL NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "level" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "user_id" INTEGER,
    "session_id" TEXT,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "url" TEXT,
    "method" TEXT,
    "status_code" INTEGER,
    "response_time" INTEGER,
    "error_stack" TEXT,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "logs_timestamp_idx" ON "logs"("timestamp");

-- CreateIndex
CREATE INDEX "logs_level_idx" ON "logs"("level");

-- CreateIndex
CREATE INDEX "logs_category_idx" ON "logs"("category");

-- CreateIndex
CREATE INDEX "logs_user_id_idx" ON "logs"("user_id");

-- CreateIndex
CREATE INDEX "logs_session_id_idx" ON "logs"("session_id");

-- CreateIndex
CREATE INDEX "logs_created_at_idx" ON "logs"("created_at");
