# DATA_SCHEMA.md

第一版数据库将在阶段 2 实现，至少包含以下表：

## applications

`id`, `company_name`, `job_title`, `job_direction`, `city`, `channel`, `status`, `priority`, `apply_date`, `next_follow_date`, `jd_link`, `resume_version`, `salary_range`, `remark`, `created_at`, `updated_at`

## stages

`id`, `application_id`, `stage_type`, `stage_time`, `result`, `questions`, `review`, `next_action`, `created_at`, `updated_at`

## materials

`id`, `name`, `type`, `direction`, `version`, `file_path`, `remark`, `created_at`, `updated_at`

## import_logs

`id`, `file_name`, `import_time`, `total_rows`, `success_rows`, `duplicate_rows`, `failed_rows`, `mapping_json`, `created_at`
