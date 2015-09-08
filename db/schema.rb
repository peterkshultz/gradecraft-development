# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150907224335) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "announcement_states", force: :cascade do |t|
    t.integer  "announcement_id"
    t.integer  "user_id"
    t.boolean  "read",            default: true
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "announcement_states", ["announcement_id"], name: "index_announcement_states_on_announcement_id", using: :btree
  add_index "announcement_states", ["user_id"], name: "index_announcement_states_on_user_id", using: :btree

  create_table "announcements", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "author_id"
    t.integer  "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "announcements", ["author_id"], name: "index_announcements_on_author_id", using: :btree
  add_index "announcements", ["course_id"], name: "index_announcements_on_course_id", using: :btree

  create_table "assignment_files", force: :cascade do |t|
    t.string   "filename",        limit: 255
    t.integer  "assignment_id"
    t.string   "filepath",        limit: 255
    t.string   "file",            limit: 255
    t.boolean  "file_processing",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assignment_groups", force: :cascade do |t|
    t.integer "group_id"
    t.integer "assignment_id"
  end

  create_table "assignment_score_levels", force: :cascade do |t|
    t.integer  "assignment_id",             null: false
    t.string   "name",          limit: 255, null: false
    t.integer  "value",                     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "assignment_submissions", force: :cascade do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.string   "feedback",                limit: 255
    t.string   "comment",                 limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "attachment_file_name",    limit: 255
    t.string   "attachment_content_type", limit: 255
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "link",                    limit: 255
    t.integer  "submittable_id"
    t.string   "submittable_type",        limit: 255
    t.text     "text_feedback"
    t.text     "text_comment"
  end

  create_table "assignment_types", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.string   "point_setting",            limit: 255
    t.boolean  "levels"
    t.string   "points_predictor_display", limit: 255
    t.integer  "resubmission"
    t.integer  "max_value"
    t.integer  "percentage_course"
    t.text     "predictor_description"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "course_id"
    t.integer  "universal_point_value"
    t.integer  "minimum_score"
    t.integer  "step_value",                           default: 1
    t.integer  "grade_scheme_id"
    t.boolean  "due_date_present"
    t.integer  "order_placement"
    t.boolean  "mass_grade"
    t.string   "mass_grade_type",          limit: 255
    t.boolean  "student_weightable"
    t.boolean  "notify_released",                      default: true
    t.boolean  "include_in_timeline",                  default: true
    t.boolean  "include_in_predictor",                 default: true
    t.boolean  "include_in_to_do",                     default: true
    t.boolean  "is_attendance"
    t.boolean  "has_winners"
    t.integer  "num_winner_levels"
    t.integer  "position"
  end

  create_table "assignment_weights", force: :cascade do |t|
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "student_id",                     null: false
    t.integer  "assignment_type_id",             null: false
    t.integer  "weight",                         null: false
    t.integer  "assignment_id",                  null: false
    t.integer  "course_id"
    t.integer  "point_total",        default: 0, null: false
  end

  add_index "assignment_weights", ["assignment_id"], name: "index_assignment_weights_on_assignment_id", using: :btree
  add_index "assignment_weights", ["course_id"], name: "index_assignment_weights_on_course_id", using: :btree
  add_index "assignment_weights", ["student_id", "assignment_id"], name: "index_weights_on_student_id_and_assignment_id", unique: true, using: :btree
  add_index "assignment_weights", ["student_id", "assignment_type_id"], name: "index_assignment_weights_on_student_id_and_assignment_type_id", using: :btree

  create_table "assignments", force: :cascade do |t|
    t.string   "name",                              limit: 255
    t.text     "description"
    t.integer  "point_total"
    t.datetime "due_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "level",                             limit: 255
    t.boolean  "present"
    t.integer  "course_id"
    t.integer  "assignment_type_id"
    t.integer  "grade_scheme_id"
    t.string   "grade_scope",                       limit: 255, default: "Individual", null: false
    t.datetime "close_time"
    t.datetime "open_time"
    t.boolean  "required"
    t.boolean  "accepts_submissions"
    t.boolean  "student_logged"
    t.boolean  "release_necessary",                             default: false,        null: false
    t.datetime "open_at"
    t.string   "icon",                              limit: 255
    t.boolean  "can_earn_multiple_times"
    t.boolean  "visible",                                       default: true
    t.integer  "category_id"
    t.boolean  "resubmissions_allowed"
    t.integer  "max_submissions"
    t.datetime "accepts_submissions_until"
    t.datetime "accepts_resubmissions_until"
    t.datetime "grading_due_at"
    t.string   "role_necessary_for_release",        limit: 255
    t.string   "media",                             limit: 255
    t.string   "thumbnail",                         limit: 255
    t.string   "media_credit",                      limit: 255
    t.string   "media_caption",                     limit: 255
    t.string   "points_predictor_display",          limit: 255
    t.boolean  "notify_released",                               default: true
    t.string   "mass_grade_type",                   limit: 255
    t.boolean  "include_in_timeline",                           default: true
    t.boolean  "include_in_predictor",                          default: true
    t.integer  "position"
    t.boolean  "include_in_to_do",                              default: true
    t.boolean  "use_rubric",                                    default: true
    t.string   "student_logged_button_text",        limit: 255
    t.string   "student_logged_revert_button_text", limit: 255
    t.boolean  "accepts_attachments",                           default: true
    t.boolean  "accepts_text",                                  default: true
    t.boolean  "accepts_links",                                 default: true
    t.boolean  "pass_fail",                                     default: false
    t.boolean  "hide_analytics"
    t.boolean  "visible_when_locked",                           default: true
  end

  add_index "assignments", ["course_id"], name: "index_assignments_on_course_id", using: :btree

  create_table "badge_files", force: :cascade do |t|
    t.string   "filename",        limit: 255
    t.integer  "badge_id"
    t.string   "filepath",        limit: 255
    t.string   "file",            limit: 255
    t.boolean  "file_processing",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badge_sets", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.integer  "course_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "badge_sets_courses", id: false, force: :cascade do |t|
    t.integer "course_id"
    t.integer "badge_set_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.text     "description"
    t.integer  "point_total"
    t.integer  "course_id"
    t.integer  "assignment_id"
    t.integer  "badge_set_id"
    t.string   "icon",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "visible",                             default: true
    t.boolean  "can_earn_multiple_times",             default: true
    t.integer  "position"
    t.boolean  "visible_when_locked",                 default: true
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "course_id"
  end

  add_index "categories", ["course_id"], name: "index_categories_on_course_id", using: :btree

  create_table "challenge_files", force: :cascade do |t|
    t.string   "filename",        limit: 255
    t.integer  "challenge_id"
    t.string   "filepath",        limit: 255
    t.string   "file",            limit: 255
    t.boolean  "file_processing",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "challenge_grades", force: :cascade do |t|
    t.integer  "challenge_id"
    t.integer  "score"
    t.string   "feedback",      limit: 255
    t.string   "status",        limit: 255
    t.integer  "team_id"
    t.integer  "final_score"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "text_feedback"
  end

  create_table "challenge_score_levels", force: :cascade do |t|
    t.integer  "challenge_id"
    t.string   "name",         limit: 255
    t.integer  "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "challenges", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.text     "description"
    t.integer  "point_total"
    t.datetime "due_at"
    t.integer  "course_id"
    t.string   "points_predictor_display", limit: 255
    t.boolean  "visible",                              default: true
    t.boolean  "accepts_submissions"
    t.boolean  "release_necessary"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.datetime "open_at"
    t.boolean  "mass_grade"
    t.string   "mass_grade_type",          limit: 255
    t.boolean  "levels"
    t.string   "media",                    limit: 255
    t.string   "thumbnail",                limit: 255
    t.string   "media_credit",             limit: 255
    t.string   "media_caption",            limit: 255
  end

  create_table "course_badge_sets", force: :cascade do |t|
    t.integer "course_id"
    t.integer "badge_set_id"
  end

  create_table "course_categories", id: false, force: :cascade do |t|
    t.integer "course_id"
    t.integer "category_id"
  end

  create_table "course_grade_scheme_elements", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "letter_grade",           limit: 255
    t.integer  "low_range"
    t.integer  "high_range"
    t.integer  "course_grade_scheme_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "course_grade_schemes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "course_id"
  end

  create_table "course_memberships", force: :cascade do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "score",                            default: 0,         null: false
    t.boolean  "shared_badges"
    t.text     "character_profile"
    t.datetime "last_login_at"
    t.boolean  "auditing",                         default: false,     null: false
    t.string   "role",                 limit: 255, default: "student", null: false
    t.boolean  "instructor_of_record",             default: false
  end

  add_index "course_memberships", ["course_id", "user_id"], name: "index_course_memberships_on_course_id_and_user_id", unique: true, using: :btree
  add_index "course_memberships", ["course_id", "user_id"], name: "index_courses_users_on_course_id_and_user_id", using: :btree
  add_index "course_memberships", ["user_id", "course_id"], name: "index_courses_users_on_user_id_and_course_id", using: :btree

  create_table "courses", force: :cascade do |t|
    t.string   "name",                              limit: 255
    t.string   "courseno",                          limit: 255
    t.string   "year",                              limit: 255
    t.string   "semester",                          limit: 255
    t.integer  "grade_scheme_id"
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
    t.boolean  "badge_setting",                                                         default: true
    t.boolean  "team_setting",                                                          default: false
    t.string   "user_term",                         limit: 255
    t.string   "team_term",                         limit: 255
    t.string   "homepage_message",                  limit: 255
    t.boolean  "status",                                                                default: true
    t.boolean  "group_setting"
    t.integer  "badge_set_id"
    t.datetime "assignment_weight_close_at"
    t.boolean  "team_roles"
    t.string   "team_leader_term",                  limit: 255
    t.string   "group_term",                        limit: 255
    t.string   "assignment_weight_type",            limit: 255
    t.boolean  "accepts_submissions"
    t.boolean  "teams_visible"
    t.string   "badge_use_scope",                   limit: 255
    t.string   "weight_term",                       limit: 255
    t.boolean  "predictor_setting"
    t.boolean  "badges_value"
    t.integer  "max_group_size"
    t.integer  "min_group_size"
    t.boolean  "shared_badges"
    t.boolean  "graph_display"
    t.decimal  "default_assignment_weight",                     precision: 4, scale: 1, default: 1.0
    t.string   "tagline",                           limit: 255
    t.boolean  "academic_history_visible"
    t.string   "office",                            limit: 255
    t.string   "phone",                             limit: 255
    t.string   "class_email",                       limit: 255
    t.string   "twitter_handle",                    limit: 255
    t.string   "twitter_hashtag",                   limit: 255
    t.string   "location",                          limit: 255
    t.string   "office_hours",                      limit: 255
    t.text     "meeting_times"
    t.string   "media",                             limit: 255
    t.string   "media_credit",                      limit: 255
    t.string   "media_caption",                     limit: 255
    t.string   "badge_term",                        limit: 255
    t.string   "assignment_term",                   limit: 255
    t.string   "challenge_term",                    limit: 255
    t.boolean  "use_timeline"
    t.text     "grading_philosophy"
    t.integer  "total_assignment_weight"
    t.integer  "max_assignment_weight"
    t.boolean  "check_final_grade"
    t.boolean  "character_profiles"
    t.string   "lti_uid",                           limit: 255
    t.boolean  "team_score_average"
    t.boolean  "team_challenges"
    t.integer  "max_assignment_types_weighted"
    t.integer  "point_total"
    t.boolean  "in_team_leaderboard"
    t.boolean  "add_team_score_to_student",                                             default: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.string   "pass_term",                         limit: 255
    t.string   "fail_term",                         limit: 255
    t.string   "syllabus"
    t.boolean  "hide_analytics"
    t.string   "character_names"
    t.boolean  "show_see_details_link_in_timeline",                                     default: true
  end

  add_index "courses", ["lti_uid"], name: "index_courses_on_lti_uid", using: :btree

  create_table "dashboards", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "duplicated_users", id: false, force: :cascade do |t|
    t.integer "id"
    t.string  "last_name",   limit: 255
    t.string  "role",        limit: 255
    t.integer "submissions", limit: 8
  end

  create_table "earned_badges", force: :cascade do |t|
    t.integer  "badge_id"
    t.integer  "submission_id"
    t.integer  "course_id"
    t.integer  "student_id"
    t.integer  "task_id"
    t.integer  "grade_id"
    t.integer  "group_id"
    t.string   "group_type",      limit: 255
    t.integer  "score"
    t.text     "feedback"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "shared"
    t.integer  "assignment_id"
    t.integer  "rubric_grade_id"
    t.integer  "metric_id"
    t.integer  "tier_id"
    t.integer  "tier_badge_id"
    t.boolean  "student_visible",             default: false
  end

  add_index "earned_badges", ["grade_id", "badge_id"], name: "index_earned_badges_on_grade_id_and_badge_id", unique: true, using: :btree

  create_table "elements", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.integer  "badge_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "events", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.text     "description"
    t.datetime "open_at"
    t.datetime "due_at"
    t.text     "media"
    t.text     "thumbnail"
    t.text     "media_credit"
    t.string   "media_caption", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
  end

  create_table "faqs", force: :cascade do |t|
    t.string   "question",   limit: 255
    t.text     "answer"
    t.integer  "order"
    t.string   "category",   limit: 255
    t.string   "audience",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "grade_files", force: :cascade do |t|
    t.integer  "grade_id"
    t.string   "filename",        limit: 255
    t.string   "filepath",        limit: 255
    t.string   "file",            limit: 255
    t.boolean  "file_processing",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "grade_scheme_elements", force: :cascade do |t|
    t.string   "level",           limit: 255
    t.integer  "low_range"
    t.string   "letter",          limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "grade_scheme_id"
    t.string   "description",     limit: 255
    t.integer  "high_range"
    t.integer  "course_id"
  end

  create_table "grade_schemes", force: :cascade do |t|
    t.integer  "assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.string   "name",          limit: 255
    t.text     "description"
  end

  create_table "grades", force: :cascade do |t|
    t.integer  "raw_score"
    t.integer  "assignment_id"
    t.text     "feedback"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "complete"
    t.boolean  "semis"
    t.boolean  "finals"
    t.string   "type",                 limit: 255
    t.string   "status",               limit: 255
    t.boolean  "attempted"
    t.boolean  "substantial"
    t.integer  "final_score"
    t.integer  "submission_id"
    t.integer  "course_id"
    t.boolean  "shared"
    t.integer  "student_id"
    t.integer  "task_id"
    t.integer  "group_id"
    t.string   "group_type",           limit: 255
    t.integer  "score"
    t.integer  "assignment_type_id"
    t.integer  "point_total"
    t.text     "admin_notes"
    t.integer  "graded_by_id"
    t.integer  "team_id"
    t.integer  "predicted_score"
    t.boolean  "instructor_modified",              default: false
    t.string   "pass_fail_status"
    t.boolean  "feedback_read",                    default: false
    t.datetime "feedback_read_at"
    t.boolean  "feedback_reviewed",                default: false
    t.datetime "feedback_reviewed_at"
    t.boolean  "is_custom_value",                  default: false
  end

  add_index "grades", ["assignment_id", "student_id"], name: "index_grades_on_assignment_id_and_student_id", unique: true, using: :btree
  add_index "grades", ["assignment_id", "task_id", "submission_id"], name: "index_grades_on_assignment_id_and_task_id_and_submission_id", unique: true, using: :btree
  add_index "grades", ["assignment_id"], name: "index_grades_on_assignment_id", using: :btree
  add_index "grades", ["assignment_type_id"], name: "index_grades_on_assignment_type_id", using: :btree
  add_index "grades", ["course_id"], name: "index_grades_on_course_id", using: :btree
  add_index "grades", ["group_id", "group_type"], name: "index_grades_on_group_id_and_group_type", using: :btree
  add_index "grades", ["score"], name: "index_grades_on_score", using: :btree
  add_index "grades", ["task_id"], name: "index_grades_on_task_id", using: :btree

  create_table "group_memberships", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "student_id"
    t.string   "accepted",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "course_id"
    t.string   "group_type", limit: 255
  end

  add_index "group_memberships", ["course_id"], name: "index_group_memberships_on_course_id", using: :btree
  add_index "group_memberships", ["group_id", "group_type"], name: "index_group_memberships_on_group_id_and_group_type", using: :btree
  add_index "group_memberships", ["student_id"], name: "index_group_memberships_on_student_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.string   "approved",      limit: 255
    t.text     "text_feedback"
    t.text     "text_proposal"
  end

  create_table "lti_providers", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "uid",             limit: 255
    t.string   "consumer_key",    limit: 255
    t.string   "consumer_secret", limit: 255
    t.string   "launch_url",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metric_badges", force: :cascade do |t|
    t.integer  "metric_id"
    t.integer  "badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metrics", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.text     "description"
    t.integer  "max_points"
    t.integer  "rubric_id"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "full_credit_tier_id"
    t.integer  "tiers_count",                     default: 0
  end

  create_table "predicted_earned_badges", force: :cascade do |t|
    t.integer  "badge_id"
    t.integer  "student_id"
    t.integer  "times_earned", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "predicted_earned_challenges", force: :cascade do |t|
    t.integer  "challenge_id"
    t.integer  "student_id"
    t.integer  "points_earned", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proposals", force: :cascade do |t|
    t.string   "title",        limit: 255
    t.text     "proposal"
    t.integer  "group_id"
    t.text     "feedback"
    t.boolean  "approved"
    t.integer  "submitted_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rubric_categories", force: :cascade do |t|
    t.integer "rubric_id"
    t.string  "name",      limit: 255
  end

  create_table "rubric_grades", force: :cascade do |t|
    t.string   "metric_name",        limit: 255
    t.text     "metric_description"
    t.integer  "max_points"
    t.integer  "order"
    t.string   "tier_name",          limit: 255
    t.text     "tier_description"
    t.integer  "points"
    t.integer  "submission_id"
    t.integer  "metric_id"
    t.integer  "tier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "assignment_id"
    t.integer  "student_id"
    t.text     "comments"
  end

  create_table "rubrics", force: :cascade do |t|
    t.integer  "assignment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "score_levels", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "value"
    t.integer  "assignment_type_id"
    t.integer  "assignment_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shared_earned_badges", force: :cascade do |t|
    t.integer  "course_id"
    t.text     "student_name"
    t.integer  "user_id"
    t.string   "icon",         limit: 255
    t.string   "name",         limit: 255
    t.integer  "badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "student_academic_histories", force: :cascade do |t|
    t.integer "student_id"
    t.string  "major",                limit: 255
    t.decimal "gpa"
    t.integer "current_term_credits"
    t.integer "accumulated_credits"
    t.string  "year_in_school",       limit: 255
    t.string  "state_of_residence",   limit: 255
    t.string  "high_school",          limit: 255
    t.boolean "athlete"
    t.integer "act_score"
    t.integer "sat_score"
  end

  create_table "student_assignment_type_weights", force: :cascade do |t|
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "student_id"
    t.integer  "assignment_type_id"
    t.integer  "weight",             null: false
  end

  create_table "submission_files", force: :cascade do |t|
    t.string   "filename",        limit: 255,                 null: false
    t.integer  "submission_id",                               null: false
    t.string   "filepath",        limit: 255
    t.string   "file",            limit: 255
    t.boolean  "file_processing",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "submission_files_duplicate", id: false, force: :cascade do |t|
    t.string  "key",        limit: 255
    t.string  "format",     limit: 255
    t.integer "upload_id"
    t.string  "full_name",  limit: 255
    t.string  "last_name",  limit: 255
    t.string  "first_name", limit: 255
  end

  create_table "submissions", force: :cascade do |t|
    t.integer  "assignment_id"
    t.integer  "student_id"
    t.string   "feedback",                limit: 255
    t.string   "comment",                 limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "attachment_file_name",    limit: 255
    t.string   "attachment_content_type", limit: 255
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "link",                    limit: 255
    t.text     "text_feedback"
    t.text     "text_comment"
    t.integer  "creator_id"
    t.integer  "group_id"
    t.boolean  "graded"
    t.datetime "released_at"
    t.integer  "task_id"
    t.integer  "course_id"
    t.integer  "assignment_type_id"
    t.string   "assignment_type",         limit: 255
  end

  add_index "submissions", ["assignment_type"], name: "index_submissions_on_assignment_type", using: :btree
  add_index "submissions", ["course_id"], name: "index_submissions_on_course_id", using: :btree

  create_table "tasks", force: :cascade do |t|
    t.integer  "assignment_id"
    t.string   "name",                limit: 255
    t.text     "description"
    t.datetime "due_at"
    t.boolean  "accepts_submissions"
    t.boolean  "group"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.string   "assignment_type",     limit: 255
    t.string   "type",                limit: 255
    t.string   "taskable_type",       limit: 255
  end

  add_index "tasks", ["assignment_id", "assignment_type"], name: "index_tasks_on_assignment_id_and_assignment_type", using: :btree
  add_index "tasks", ["course_id"], name: "index_tasks_on_course_id", using: :btree
  add_index "tasks", ["id", "type"], name: "index_tasks_on_id_and_type", using: :btree

  create_table "team_leaderships", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "leader_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "student_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "course_id"
    t.integer  "rank"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "teams_leaderboard",               default: false
    t.boolean  "in_team_leaderboard",             default: false
    t.string   "banner",              limit: 255
  end

  create_table "themes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "filename",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tier_badges", force: :cascade do |t|
    t.integer  "tier_id"
    t.integer  "badge_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tiers", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description"
    t.integer  "points"
    t.integer  "metric_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "full_credit"
    t.boolean  "no_credit"
    t.boolean  "durable"
    t.integer  "sort_order"
  end

  create_table "unlock_conditions", force: :cascade do |t|
    t.integer  "unlockable_id"
    t.string   "unlockable_type"
    t.integer  "condition_id"
    t.string   "condition_type"
    t.string   "condition_state"
    t.integer  "condition_value"
    t.datetime "condition_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "unlock_states", force: :cascade do |t|
    t.integer  "unlockable_id"
    t.string   "unlockable_type"
    t.integer  "student_id"
    t.boolean  "unlocked"
    t.boolean  "instructor_unlocked"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",                        limit: 255,                     null: false
    t.string   "email",                           limit: 255
    t.string   "crypted_password",                limit: 255
    t.string   "salt",                            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_password_token",            limit: 255
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "remember_me_token",               limit: 255
    t.datetime "remember_me_token_expires_at"
    t.string   "avatar_file_name",                limit: 255
    t.string   "avatar_content_type",             limit: 255
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "role",                            limit: 255, default: "student", null: false
    t.string   "first_name",                      limit: 255
    t.string   "last_name",                       limit: 255
    t.integer  "rank"
    t.string   "display_name",                    limit: 255
    t.boolean  "private_display",                             default: false
    t.integer  "default_course_id"
    t.string   "final_grade",                     limit: 255
    t.integer  "visit_count"
    t.integer  "predictor_views"
    t.integer  "page_views"
    t.string   "team_role",                       limit: 255
    t.datetime "last_login_at"
    t.datetime "last_logout_at"
    t.datetime "last_activity_at"
    t.string   "lti_uid",                         limit: 255
    t.string   "last_login_from_ip_address",      limit: 255
    t.string   "kerberos_uid",                    limit: 255
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
  end

  add_index "users", ["activation_token"], name: "index_users_on_activation_token", using: :btree
  add_index "users", ["kerberos_uid"], name: "index_users_on_kerberos_uid", using: :btree
  add_index "users", ["last_logout_at", "last_activity_at"], name: "index_users_on_last_logout_at_and_last_activity_at", using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree

  add_foreign_key "announcement_states", "announcements"
  add_foreign_key "announcement_states", "users"
  add_foreign_key "announcements", "courses"
  add_foreign_key "announcements", "users", column: "author_id"
end
