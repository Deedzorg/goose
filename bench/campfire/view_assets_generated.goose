// Generated from the pinned Rust static asset manifest; see views/source.json.

namespace campfire;
import std;

let VIEW_STYLESHEET_TAGS = "<link rel=\"stylesheet\" href=\"/assets/_reset-9c3efd7b.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/actiontext-7b8d51ea.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/animation-bcdb4bab.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/autocomplete-9de8c93f.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/avatars-279376ab.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/base-637a0ec8.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/boosts-da4032a8.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/buttons-c7d39fd4.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/code-333ae548.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/colorize-eb391ca0.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/colors-aee62523.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/composer-e490638a.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/embeds-c20d0a3a.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/filters-8a4d63ed.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/flash-a561c1e5.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/inputs-9e58a07c.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/layout-ff6ddfc6.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/lexxy-content-0ff2f961.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/lexxy-editor-2d5c7ebe.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/lexxy-variables-3fef4323.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/lexxy-2876c58e.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/lightbox-af496d39.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/messages-c5485fef.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/nav-05e7183a.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/panels-af44ec6d.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/separators-172b3ab8.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/sidebar-0be58db9.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/signup-6e02d591.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/spinner-5a118f25.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/trix-65afdb1d.css\" data-turbo-track=\"reload\" />\n<link rel=\"stylesheet\" href=\"/assets/utilities-e2f32466.css\" data-turbo-track=\"reload\" />";

let VIEW_IMPORTMAP_TAGS = "<script type=\"importmap\" data-turbo-track=\"reload\">{\n  \"imports\": {\n    \"application\": \"/assets/application-a54c74a7.js\",\n    \"@hotwired/stimulus\": \"/assets/stimulus.min-4b1e420e.js\",\n    \"@hotwired/stimulus-loading\": \"/assets/stimulus-loading-1fc53fe7.js\",\n    \"@hotwired/turbo-rails\": \"/assets/turbo-a1e3a50a.js\",\n    \"@rails/actioncable\": \"/assets/actioncable.esm-e0ec9819.js\",\n    \"@rails/request.js\": \"/assets/@rails--request-3fc8489d.js\",\n    \"lexxy\": \"/assets/lexxy-a21f41d4.js\",\n    \"highlight.js\": \"/assets/highlight.js/core-4e141f64.js\",\n    \"initializers/autocomplete\": \"/assets/initializers/autocomplete-ba9abe45.js\",\n    \"initializers/current\": \"/assets/initializers/current-3a3b90da.js\",\n    \"initializers/highlight\": \"/assets/initializers/highlight-5bd558f1.js\",\n    \"initializers\": \"/assets/initializers/index-d2bbfae4.js\",\n    \"initializers/rich_text\": \"/assets/initializers/rich_text-f451a05e.js\",\n    \"lib/autocomplete/autocomplete_handler\": \"/assets/lib/autocomplete/autocomplete_handler-becd1e1a.js\",\n    \"lib/autocomplete/base_autocomplete_handler\": \"/assets/lib/autocomplete/base_autocomplete_handler-96e7e419.js\",\n    \"lib/autocomplete/collection\": \"/assets/lib/autocomplete/collection-3e251a0e.js\",\n    \"lib/autocomplete/constants\": \"/assets/lib/autocomplete/constants-17c2858b.js\",\n    \"lib/autocomplete/custom_elements/suggestion_option\": \"/assets/lib/autocomplete/custom_elements/suggestion_option-ac7846b3.js\",\n    \"lib/autocomplete/custom_elements/suggestion_select\": \"/assets/lib/autocomplete/custom_elements/suggestion_select-f0045305.js\",\n    \"lib/autocomplete/helpers\": \"/assets/lib/autocomplete/helpers-651308b9.js\",\n    \"lib/autocomplete/renderer\": \"/assets/lib/autocomplete/renderer-5caf6120.js\",\n    \"lib/autocomplete/selection\": \"/assets/lib/autocomplete/selection-862705bf.js\",\n    \"lib/autocomplete/suggestion_context\": \"/assets/lib/autocomplete/suggestion_context-b265ffb4.js\",\n    \"lib/autocomplete/suggestion_controller\": \"/assets/lib/autocomplete/suggestion_controller-10624c40.js\",\n    \"lib/autocomplete/suggestion_results_controller\": \"/assets/lib/autocomplete/suggestion_results_controller-91405749.js\",\n    \"lib/autocomplete/utils\": \"/assets/lib/autocomplete/utils-296fb278.js\",\n    \"lib/cookie\": \"/assets/lib/cookie-76006835.js\",\n    \"lib/rich_text/campfire_extension\": \"/assets/lib/rich_text/campfire_extension-f62f017b.js\",\n    \"lib/rich_text/cite_node\": \"/assets/lib/rich_text/cite_node-b4d2b89a.js\",\n    \"controllers/application\": \"/assets/controllers/application-f004202c.js\",\n    \"controllers/auto_submit_controller\": \"/assets/controllers/auto_submit_controller-ee52d396.js\",\n    \"controllers/autocomplete_controller\": \"/assets/controllers/autocomplete_controller-eaf5b07d.js\",\n    \"controllers/badge_dot_controller\": \"/assets/controllers/badge_dot_controller-e0d733c8.js\",\n    \"controllers/boost_delete_controller\": \"/assets/controllers/boost_delete_controller-29fd1686.js\",\n    \"controllers/composer_controller\": \"/assets/controllers/composer_controller-73c33f9f.js\",\n    \"controllers/copy_to_clipboard_controller\": \"/assets/controllers/copy_to_clipboard_controller-a4928c72.js\",\n    \"controllers/drop_target_controller\": \"/assets/controllers/drop_target_controller-3a205782.js\",\n    \"controllers/element_removal_controller\": \"/assets/controllers/element_removal_controller-4526910a.js\",\n    \"controllers/filter_controller\": \"/assets/controllers/filter_controller-ca9769d5.js\",\n    \"controllers/form_controller\": \"/assets/controllers/form_controller-6f3d64db.js\",\n    \"controllers\": \"/assets/controllers/index-594ba2fb.js\",\n    \"controllers/lightbox_controller\": \"/assets/controllers/lightbox_controller-98fc07ca.js\",\n    \"controllers/local_time_controller\": \"/assets/controllers/local_time_controller-7daf3d0c.js\",\n    \"controllers/maintain_scroll_controller\": \"/assets/controllers/maintain_scroll_controller-1debbbfb.js\",\n    \"controllers/messages_controller\": \"/assets/controllers/messages_controller-3d90944a.js\",\n    \"controllers/notifications_controller\": \"/assets/controllers/notifications_controller-746d0662.js\",\n    \"controllers/popup_controller\": \"/assets/controllers/popup_controller-9f8ea824.js\",\n    \"controllers/presence_controller\": \"/assets/controllers/presence_controller-28f14aad.js\",\n    \"controllers/pwa_install_controller\": \"/assets/controllers/pwa_install_controller-3fe3fc5e.js\",\n    \"controllers/read_rooms_controller\": \"/assets/controllers/read_rooms_controller-8245522a.js\",\n    \"controllers/refresh_room_controller\": \"/assets/controllers/refresh_room_controller-4e4b6014.js\",\n    \"controllers/reply_controller\": \"/assets/controllers/reply_controller-278bb9cc.js\",\n    \"controllers/rooms_list_controller\": \"/assets/controllers/rooms_list_controller-8fe7485c.js\",\n    \"controllers/scroll_into_view_controller\": \"/assets/controllers/scroll_into_view_controller-8a0bc733.js\",\n    \"controllers/search_results_controller\": \"/assets/controllers/search_results_controller-aab46974.js\",\n    \"controllers/sessions_controller\": \"/assets/controllers/sessions_controller-a9fdfe3d.js\",\n    \"controllers/soft_keyboard_controller\": \"/assets/controllers/soft_keyboard_controller-be1da837.js\",\n    \"controllers/sorted_list_controller\": \"/assets/controllers/sorted_list_controller-9f9ae485.js\",\n    \"controllers/sound_controller\": \"/assets/controllers/sound_controller-d3e5656e.js\",\n    \"controllers/toggle_class_controller\": \"/assets/controllers/toggle_class_controller-b67fa681.js\",\n    \"controllers/turbo_frame_controller\": \"/assets/controllers/turbo_frame_controller-9f4f722f.js\",\n    \"controllers/turbo_streaming_controller\": \"/assets/controllers/turbo_streaming_controller-04b85a80.js\",\n    \"controllers/typing_notifications_controller\": \"/assets/controllers/typing_notifications_controller-86906ab9.js\",\n    \"controllers/unfurl_controller\": \"/assets/controllers/unfurl_controller-4a868f9a.js\",\n    \"controllers/upload_preview_controller\": \"/assets/controllers/upload_preview_controller-9b8b26bb.js\",\n    \"controllers/web_share_controller\": \"/assets/controllers/web_share_controller-f7236b6f.js\",\n    \"helpers/dom_helpers\": \"/assets/helpers/dom_helpers-0f234176.js\",\n    \"helpers/navigator_helpers\": \"/assets/helpers/navigator_helpers-3c9f4c31.js\",\n    \"helpers/string_helpers\": \"/assets/helpers/string_helpers-40941ba8.js\",\n    \"helpers/timing_helpers\": \"/assets/helpers/timing_helpers-94d95529.js\",\n    \"helpers/turbo_helpers\": \"/assets/helpers/turbo_helpers-a3c01462.js\",\n    \"models/client_message\": \"/assets/models/client_message-de3c07cf.js\",\n    \"models/file_uploader\": \"/assets/models/file_uploader-09a18428.js\",\n    \"models/message_formatter\": \"/assets/models/message_formatter-f39a0c5d.js\",\n    \"models/message_paginator\": \"/assets/models/message_paginator-b79013e3.js\",\n    \"models/scroll_manager\": \"/assets/models/scroll_manager-ed559629.js\",\n    \"models/typing_tracker\": \"/assets/models/typing_tracker-42a444a5.js\",\n    \"languages/bash\": \"/assets/languages/bash-13136668.js\",\n    \"languages/css\": \"/assets/languages/css-a7f2e40b.js\",\n    \"languages/diff\": \"/assets/languages/diff-94a335fe.js\",\n    \"languages/go\": \"/assets/languages/go-10465864.js\",\n    \"languages/java\": \"/assets/languages/java-95f3a30f.js\",\n    \"languages/javascript\": \"/assets/languages/javascript-18eb0dd8.js\",\n    \"languages/json\": \"/assets/languages/json-60184e1b.js\",\n    \"languages/python\": \"/assets/languages/python-8f48fd1a.js\",\n    \"languages/ruby\": \"/assets/languages/ruby-287ccd0f.js\",\n    \"languages/rust\": \"/assets/languages/rust-d48f93d8.js\",\n    \"languages/sql\": \"/assets/languages/sql-642be05a.js\",\n    \"languages/xml\": \"/assets/languages/xml-fa7f1eda.js\"\n  }\n}</script>\n<link rel=\"modulepreload\" href=\"/assets/application-a54c74a7.js\">\n<link rel=\"modulepreload\" href=\"/assets/stimulus.min-4b1e420e.js\">\n<link rel=\"modulepreload\" href=\"/assets/stimulus-loading-1fc53fe7.js\">\n<link rel=\"modulepreload\" href=\"/assets/turbo-a1e3a50a.js\">\n<link rel=\"modulepreload\" href=\"/assets/actioncable.esm-e0ec9819.js\">\n<link rel=\"modulepreload\" href=\"/assets/@rails--request-3fc8489d.js\">\n<link rel=\"modulepreload\" href=\"/assets/lexxy-a21f41d4.js\">\n<link rel=\"modulepreload\" href=\"/assets/highlight.js/core-4e141f64.js\">\n<link rel=\"modulepreload\" href=\"/assets/initializers/autocomplete-ba9abe45.js\">\n<link rel=\"modulepreload\" href=\"/assets/initializers/current-3a3b90da.js\">\n<link rel=\"modulepreload\" href=\"/assets/initializers/highlight-5bd558f1.js\">\n<link rel=\"modulepreload\" href=\"/assets/initializers/index-d2bbfae4.js\">\n<link rel=\"modulepreload\" href=\"/assets/initializers/rich_text-f451a05e.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/autocomplete_handler-becd1e1a.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/base_autocomplete_handler-96e7e419.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/collection-3e251a0e.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/constants-17c2858b.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/custom_elements/suggestion_option-ac7846b3.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/custom_elements/suggestion_select-f0045305.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/helpers-651308b9.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/renderer-5caf6120.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/selection-862705bf.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/suggestion_context-b265ffb4.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/suggestion_controller-10624c40.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/suggestion_results_controller-91405749.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/autocomplete/utils-296fb278.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/cookie-76006835.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/rich_text/campfire_extension-f62f017b.js\">\n<link rel=\"modulepreload\" href=\"/assets/lib/rich_text/cite_node-b4d2b89a.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/application-f004202c.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/auto_submit_controller-ee52d396.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/autocomplete_controller-eaf5b07d.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/badge_dot_controller-e0d733c8.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/boost_delete_controller-29fd1686.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/composer_controller-73c33f9f.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/copy_to_clipboard_controller-a4928c72.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/drop_target_controller-3a205782.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/element_removal_controller-4526910a.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/filter_controller-ca9769d5.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/form_controller-6f3d64db.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/index-594ba2fb.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/lightbox_controller-98fc07ca.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/local_time_controller-7daf3d0c.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/maintain_scroll_controller-1debbbfb.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/messages_controller-3d90944a.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/notifications_controller-746d0662.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/popup_controller-9f8ea824.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/presence_controller-28f14aad.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/pwa_install_controller-3fe3fc5e.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/read_rooms_controller-8245522a.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/refresh_room_controller-4e4b6014.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/reply_controller-278bb9cc.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/rooms_list_controller-8fe7485c.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/scroll_into_view_controller-8a0bc733.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/search_results_controller-aab46974.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/sessions_controller-a9fdfe3d.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/soft_keyboard_controller-be1da837.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/sorted_list_controller-9f9ae485.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/sound_controller-d3e5656e.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/toggle_class_controller-b67fa681.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/turbo_frame_controller-9f4f722f.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/turbo_streaming_controller-04b85a80.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/typing_notifications_controller-86906ab9.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/unfurl_controller-4a868f9a.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/upload_preview_controller-9b8b26bb.js\">\n<link rel=\"modulepreload\" href=\"/assets/controllers/web_share_controller-f7236b6f.js\">\n<link rel=\"modulepreload\" href=\"/assets/helpers/dom_helpers-0f234176.js\">\n<link rel=\"modulepreload\" href=\"/assets/helpers/navigator_helpers-3c9f4c31.js\">\n<link rel=\"modulepreload\" href=\"/assets/helpers/string_helpers-40941ba8.js\">\n<link rel=\"modulepreload\" href=\"/assets/helpers/timing_helpers-94d95529.js\">\n<link rel=\"modulepreload\" href=\"/assets/helpers/turbo_helpers-a3c01462.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/client_message-de3c07cf.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/file_uploader-09a18428.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/message_formatter-f39a0c5d.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/message_paginator-b79013e3.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/scroll_manager-ed559629.js\">\n<link rel=\"modulepreload\" href=\"/assets/models/typing_tracker-42a444a5.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/bash-13136668.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/css-a7f2e40b.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/diff-94a335fe.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/go-10465864.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/java-95f3a30f.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/javascript-18eb0dd8.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/json-60184e1b.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/python-8f48fd1a.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/ruby-287ccd0f.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/rust-d48f93d8.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/sql-642be05a.js\">\n<link rel=\"modulepreload\" href=\"/assets/languages/xml-fa7f1eda.js\">\n<script type=\"module\">import \"application\"</script>";

fn asset_logical_index(name: const u8[:]) -> i64 {
    let order = compare(name, "laptop.svg");
    if order == 0 { return 157; }
    if order < 0 {
        let order = compare(name, "controllers/soft_keyboard_controller.js");
        if order == 0 { return 78; }
        if order < 0 {
            let order = compare(name, "buttons.css");
            if order == 0 { return 39; }
            if order < 0 {
                let order = compare(name, "art.svg");
                if order == 0 { return 19; }
                if order < 0 {
                    let order = compare(name, "activestorage.esm.js");
                    if order == 0 { return 9; }
                    if order < 0 {
                        let order = compare(name, "actioncable.esm.js");
                        if order == 0 { return 4; }
                        if order < 0 {
                            let order = compare(name, "_reset.css");
                            if order == 0 { return 2; }
                            if order < 0 {
                                let order = compare(name, "@rails--request.js");
                                if order == 0 { return 1; }
                                if order < 0 {
                                    let order = compare(name, "56k.mp3");
                                    if order == 0 { return 0; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "action_cable.js");
                                if order == 0 { return 3; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "actiontext.esm.js");
                            if order == 0 { return 7; }
                            if order < 0 {
                                let order = compare(name, "actiontext.css");
                                if order == 0 { return 6; }
                                if order < 0 {
                                    let order = compare(name, "actioncable.js");
                                    if order == 0 { return 5; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "actiontext.js");
                                if order == 0 { return 8; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "application.js");
                        if order == 0 { return 14; }
                        if order < 0 {
                            let order = compare(name, "alert.svg");
                            if order == 0 { return 12; }
                            if order < 0 {
                                let order = compare(name, "add.svg");
                                if order == 0 { return 11; }
                                if order < 0 {
                                    let order = compare(name, "activestorage.js");
                                    if order == 0 { return 10; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "animation.css");
                                if order == 0 { return 13; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "arrow-right.svg");
                            if order == 0 { return 17; }
                            if order < 0 {
                                let order = compare(name, "arrow-left.svg");
                                if order == 0 { return 16; }
                                if order < 0 {
                                    let order = compare(name, "arrow-down.svg");
                                    if order == 0 { return 15; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "arrow-up.svg");
                                if order == 0 { return 18; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "boosts.css");
                    if order == 0 { return 29; }
                    if order < 0 {
                        let order = compare(name, "base.css");
                        if order == 0 { return 24; }
                        if order < 0 {
                            let order = compare(name, "avatars.css");
                            if order == 0 { return 22; }
                            if order < 0 {
                                let order = compare(name, "autocomplete.css");
                                if order == 0 { return 21; }
                                if order < 0 {
                                    let order = compare(name, "attachment.svg");
                                    if order == 0 { return 20; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "ballmer.mp3");
                                if order == 0 { return 23; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "bio.svg");
                            if order == 0 { return 27; }
                            if order < 0 {
                                let order = compare(name, "bezos.mp3");
                                if order == 0 { return 26; }
                                if order < 0 {
                                    let order = compare(name, "bell.mp3");
                                    if order == 0 { return 25; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "boost.svg");
                                if order == 0 { return 28; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "browsers/edge.svg");
                        if order == 0 { return 34; }
                        if order < 0 {
                            let order = compare(name, "browsers/android.svg");
                            if order == 0 { return 32; }
                            if order < 0 {
                                let order = compare(name, "broom.svg");
                                if order == 0 { return 31; }
                                if order < 0 {
                                    let order = compare(name, "bot.svg");
                                    if order == 0 { return 30; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "browsers/chrome.svg");
                                if order == 0 { return 33; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "browsers/safari.svg");
                            if order == 0 { return 37; }
                            if order < 0 {
                                let order = compare(name, "browsers/opera.svg");
                                if order == 0 { return 36; }
                                if order < 0 {
                                    let order = compare(name, "browsers/firefox.svg");
                                    if order == 0 { return 35; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "bueller.mp3");
                                if order == 0 { return 38; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "controllers/element_removal_controller.js");
                if order == 0 { return 59; }
                if order < 0 {
                    let order = compare(name, "common-file-text.svg");
                    if order == 0 { return 49; }
                    if order < 0 {
                        let order = compare(name, "check.svg");
                        if order == 0 { return 44; }
                        if order < 0 {
                            let order = compare(name, "campfire-icon.png");
                            if order == 0 { return 42; }
                            if order < 0 {
                                let order = compare(name, "camera.svg");
                                if order == 0 { return 41; }
                                if order < 0 {
                                    let order = compare(name, "butts.mp3");
                                    if order == 0 { return 40; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "cancel.svg");
                                if order == 0 { return 43; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "colorize.css");
                            if order == 0 { return 47; }
                            if order < 0 {
                                let order = compare(name, "code.css");
                                if order == 0 { return 46; }
                                if order < 0 {
                                    let order = compare(name, "clowntown.mp3");
                                    if order == 0 { return 45; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "colors.css");
                                if order == 0 { return 48; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "controllers/badge_dot_controller.js");
                        if order == 0 { return 54; }
                        if order < 0 {
                            let order = compare(name, "controllers/auto_submit_controller.js");
                            if order == 0 { return 52; }
                            if order < 0 {
                                let order = compare(name, "controllers/application.js");
                                if order == 0 { return 51; }
                                if order < 0 {
                                    let order = compare(name, "composer.css");
                                    if order == 0 { return 50; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/autocomplete_controller.js");
                                if order == 0 { return 53; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "controllers/copy_to_clipboard_controller.js");
                            if order == 0 { return 57; }
                            if order < 0 {
                                let order = compare(name, "controllers/composer_controller.js");
                                if order == 0 { return 56; }
                                if order < 0 {
                                    let order = compare(name, "controllers/boost_delete_controller.js");
                                    if order == 0 { return 55; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/drop_target_controller.js");
                                if order == 0 { return 58; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "controllers/presence_controller.js");
                    if order == 0 { return 69; }
                    if order < 0 {
                        let order = compare(name, "controllers/local_time_controller.js");
                        if order == 0 { return 64; }
                        if order < 0 {
                            let order = compare(name, "controllers/index.js");
                            if order == 0 { return 62; }
                            if order < 0 {
                                let order = compare(name, "controllers/form_controller.js");
                                if order == 0 { return 61; }
                                if order < 0 {
                                    let order = compare(name, "controllers/filter_controller.js");
                                    if order == 0 { return 60; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/lightbox_controller.js");
                                if order == 0 { return 63; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "controllers/notifications_controller.js");
                            if order == 0 { return 67; }
                            if order < 0 {
                                let order = compare(name, "controllers/messages_controller.js");
                                if order == 0 { return 66; }
                                if order < 0 {
                                    let order = compare(name, "controllers/maintain_scroll_controller.js");
                                    if order == 0 { return 65; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/popup_controller.js");
                                if order == 0 { return 68; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "controllers/rooms_list_controller.js");
                        if order == 0 { return 74; }
                        if order < 0 {
                            let order = compare(name, "controllers/refresh_room_controller.js");
                            if order == 0 { return 72; }
                            if order < 0 {
                                let order = compare(name, "controllers/read_rooms_controller.js");
                                if order == 0 { return 71; }
                                if order < 0 {
                                    let order = compare(name, "controllers/pwa_install_controller.js");
                                    if order == 0 { return 70; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/reply_controller.js");
                                if order == 0 { return 73; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "controllers/search_results_controller.js");
                            if order == 0 { return 76; }
                            if order < 0 {
                                let order = compare(name, "controllers/scroll_into_view_controller.js");
                                if order == 0 { return 75; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/sessions_controller.js");
                                if order == 0 { return 77; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let order = compare(name, "gogogo.mp3");
            if order == 0 { return 118; }
            if order < 0 {
                let order = compare(name, "default-bot-avatar.svg");
                if order == 0 { return 98; }
                if order < 0 {
                    let order = compare(name, "copy-paste.svg");
                    if order == 0 { return 88; }
                    if order < 0 {
                        let order = compare(name, "controllers/turbo_streaming_controller.js");
                        if order == 0 { return 83; }
                        if order < 0 {
                            let order = compare(name, "controllers/toggle_class_controller.js");
                            if order == 0 { return 81; }
                            if order < 0 {
                                let order = compare(name, "controllers/sound_controller.js");
                                if order == 0 { return 80; }
                                if order < 0 {
                                    let order = compare(name, "controllers/sorted_list_controller.js");
                                    if order == 0 { return 79; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/turbo_frame_controller.js");
                                if order == 0 { return 82; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "controllers/upload_preview_controller.js");
                            if order == 0 { return 86; }
                            if order < 0 {
                                let order = compare(name, "controllers/unfurl_controller.js");
                                if order == 0 { return 85; }
                                if order < 0 {
                                    let order = compare(name, "controllers/typing_notifications_controller.js");
                                    if order == 0 { return 84; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "controllers/web_share_controller.js");
                                if order == 0 { return 87; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "dadgummit.mp3");
                        if order == 0 { return 93; }
                        if order < 0 {
                            let order = compare(name, "crown.svg");
                            if order == 0 { return 91; }
                            if order < 0 {
                                let order = compare(name, "crickets.mp3");
                                if order == 0 { return 90; }
                                if order < 0 {
                                    let order = compare(name, "cottoneyejoe.mp3");
                                    if order == 0 { return 89; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "curb.mp3");
                                if order == 0 { return 92; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "deeper.mp3");
                            if order == 0 { return 96; }
                            if order < 0 {
                                let order = compare(name, "danielsan.mp3");
                                if order == 0 { return 95; }
                                if order < 0 {
                                    let order = compare(name, "dangerzone.mp3");
                                    if order == 0 { return 94; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "default-avatar.svg");
                                if order == 0 { return 97; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "external/install.svg");
                    if order == 0 { return 108; }
                    if order < 0 {
                        let order = compare(name, "email.svg");
                        if order == 0 { return 103; }
                        if order < 0 {
                            let order = compare(name, "download.svg");
                            if order == 0 { return 101; }
                            if order < 0 {
                                let order = compare(name, "donotwant.mp3");
                                if order == 0 { return 100; }
                                if order < 0 {
                                    let order = compare(name, "disclosure.svg");
                                    if order == 0 { return 99; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "drama.mp3");
                                if order == 0 { return 102; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "external/gear.svg");
                            if order == 0 { return 106; }
                            if order < 0 {
                                let order = compare(name, "everyone.svg");
                                if order == 0 { return 105; }
                                if order < 0 {
                                    let order = compare(name, "embeds.css");
                                    if order == 0 { return 104; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "external/install-edge.svg");
                                if order == 0 { return 107; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "filters.css");
                        if order == 0 { return 113; }
                        if order < 0 {
                            let order = compare(name, "external/switch.svg");
                            if order == 0 { return 111; }
                            if order < 0 {
                                let order = compare(name, "external/sliders.svg");
                                if order == 0 { return 110; }
                                if order < 0 {
                                    let order = compare(name, "external/share.svg");
                                    if order == 0 { return 109; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "external/web.svg");
                                if order == 0 { return 112; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "glados.mp3");
                            if order == 0 { return 116; }
                            if order < 0 {
                                let order = compare(name, "flawless.mp3");
                                if order == 0 { return 115; }
                                if order < 0 {
                                    let order = compare(name, "flash.css");
                                    if order == 0 { return 114; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "globe.svg");
                                if order == 0 { return 117; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "initializers/highlight.js");
                if order == 0 { return 138; }
                if order < 0 {
                    let order = compare(name, "helpers/turbo_helpers.js");
                    if order == 0 { return 128; }
                    if order < 0 {
                        let order = compare(name, "help.svg");
                        if order == 0 { return 123; }
                        if order < 0 {
                            let order = compare(name, "guarantee.mp3");
                            if order == 0 { return 121; }
                            if order < 0 {
                                let order = compare(name, "greyjoy.mp3");
                                if order == 0 { return 120; }
                                if order < 0 {
                                    let order = compare(name, "greatjob.mp3");
                                    if order == 0 { return 119; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "help-circle.svg");
                                if order == 0 { return 122; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "helpers/string_helpers.js");
                            if order == 0 { return 126; }
                            if order < 0 {
                                let order = compare(name, "helpers/navigator_helpers.js");
                                if order == 0 { return 125; }
                                if order < 0 {
                                    let order = compare(name, "helpers/dom_helpers.js");
                                    if order == 0 { return 124; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "helpers/timing_helpers.js");
                                if order == 0 { return 127; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "horror.mp3");
                        if order == 0 { return 133; }
                        if order < 0 {
                            let order = compare(name, "honk.mp3");
                            if order == 0 { return 131; }
                            if order < 0 {
                                let order = compare(name, "highlight.js/core.js");
                                if order == 0 { return 130; }
                                if order < 0 {
                                    let order = compare(name, "heygirl.mp3");
                                    if order == 0 { return 129; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "horn.mp3");
                                if order == 0 { return 132; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "initializers/autocomplete.js");
                            if order == 0 { return 136; }
                            if order < 0 {
                                let order = compare(name, "inconceivable.mp3");
                                if order == 0 { return 135; }
                                if order < 0 {
                                    let order = compare(name, "incoming.mp3");
                                    if order == 0 { return 134; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "initializers/current.js");
                                if order == 0 { return 137; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "languages/java.js");
                    if order == 0 { return 148; }
                    if order < 0 {
                        let order = compare(name, "key.svg");
                        if order == 0 { return 143; }
                        if order < 0 {
                            let order = compare(name, "inputs.css");
                            if order == 0 { return 141; }
                            if order < 0 {
                                let order = compare(name, "initializers/rich_text.js");
                                if order == 0 { return 140; }
                                if order < 0 {
                                    let order = compare(name, "initializers/index.js");
                                    if order == 0 { return 139; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "install-edge.svg");
                                if order == 0 { return 142; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "languages/diff.js");
                            if order == 0 { return 146; }
                            if order < 0 {
                                let order = compare(name, "languages/css.js");
                                if order == 0 { return 145; }
                                if order < 0 {
                                    let order = compare(name, "languages/bash.js");
                                    if order == 0 { return 144; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "languages/go.js");
                                if order == 0 { return 147; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "languages/rust.js");
                        if order == 0 { return 153; }
                        if order < 0 {
                            let order = compare(name, "languages/python.js");
                            if order == 0 { return 151; }
                            if order < 0 {
                                let order = compare(name, "languages/json.js");
                                if order == 0 { return 150; }
                                if order < 0 {
                                    let order = compare(name, "languages/javascript.js");
                                    if order == 0 { return 149; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "languages/ruby.js");
                                if order == 0 { return 152; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "languages/xml.js");
                            if order == 0 { return 155; }
                            if order < 0 {
                                let order = compare(name, "languages/sql.js");
                                if order == 0 { return 154; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lanyard.svg");
                                if order == 0 { return 156; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        let order = compare(name, "rails-ujs.js");
        if order == 0 { return 236; }
        if order < 0 {
            let order = compare(name, "makeitso.mp3");
            if order == 0 { return 197; }
            if order < 0 {
                let order = compare(name, "lib/autocomplete/helpers.js");
                if order == 0 { return 177; }
                if order < 0 {
                    let order = compare(name, "lexxy.js.map");
                    if order == 0 { return 167; }
                    if order < 0 {
                        let order = compare(name, "lexxy-variables.css");
                        if order == 0 { return 162; }
                        if order < 0 {
                            let order = compare(name, "lexxy-content.css");
                            if order == 0 { return 160; }
                            if order < 0 {
                                let order = compare(name, "letitgo.mp3");
                                if order == 0 { return 159; }
                                if order < 0 {
                                    let order = compare(name, "layout.css");
                                    if order == 0 { return 158; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lexxy-editor.css");
                                if order == 0 { return 161; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "lexxy.js.br");
                            if order == 0 { return 165; }
                            if order < 0 {
                                let order = compare(name, "lexxy.js");
                                if order == 0 { return 164; }
                                if order < 0 {
                                    let order = compare(name, "lexxy.css");
                                    if order == 0 { return 163; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lexxy.js.gz");
                                if order == 0 { return 166; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "lib/autocomplete/base_autocomplete_handler.js");
                        if order == 0 { return 172; }
                        if order < 0 {
                            let order = compare(name, "lexxy.min.js.gz");
                            if order == 0 { return 170; }
                            if order < 0 {
                                let order = compare(name, "lexxy.min.js.br");
                                if order == 0 { return 169; }
                                if order < 0 {
                                    let order = compare(name, "lexxy.min.js");
                                    if order == 0 { return 168; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lib/autocomplete/autocomplete_handler.js");
                                if order == 0 { return 171; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "lib/autocomplete/custom_elements/suggestion_option.js");
                            if order == 0 { return 175; }
                            if order < 0 {
                                let order = compare(name, "lib/autocomplete/constants.js");
                                if order == 0 { return 174; }
                                if order < 0 {
                                    let order = compare(name, "lib/autocomplete/collection.js");
                                    if order == 0 { return 173; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lib/autocomplete/custom_elements/suggestion_select.js");
                                if order == 0 { return 176; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "lifebuoy.svg");
                    if order == 0 { return 187; }
                    if order < 0 {
                        let order = compare(name, "lib/autocomplete/suggestion_results_controller.js");
                        if order == 0 { return 182; }
                        if order < 0 {
                            let order = compare(name, "lib/autocomplete/suggestion_context.js");
                            if order == 0 { return 180; }
                            if order < 0 {
                                let order = compare(name, "lib/autocomplete/selection.js");
                                if order == 0 { return 179; }
                                if order < 0 {
                                    let order = compare(name, "lib/autocomplete/renderer.js");
                                    if order == 0 { return 178; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lib/autocomplete/suggestion_controller.js");
                                if order == 0 { return 181; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "lib/rich_text/campfire_extension.js");
                            if order == 0 { return 185; }
                            if order < 0 {
                                let order = compare(name, "lib/cookie.js");
                                if order == 0 { return 184; }
                                if order < 0 {
                                    let order = compare(name, "lib/autocomplete/utils.js");
                                    if order == 0 { return 183; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lib/rich_text/cite_node.js");
                                if order == 0 { return 186; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "loggins.mp3");
                        if order == 0 { return 192; }
                        if order < 0 {
                            let order = compare(name, "live.mp3");
                            if order == 0 { return 190; }
                            if order < 0 {
                                let order = compare(name, "link.svg");
                                if order == 0 { return 189; }
                                if order < 0 {
                                    let order = compare(name, "lightbox.css");
                                    if order == 0 { return 188; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "lock.svg");
                                if order == 0 { return 191; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "logos/app-icon.png");
                            if order == 0 { return 195; }
                            if order < 0 {
                                let order = compare(name, "logos/app-icon-192.png");
                                if order == 0 { return 194; }
                                if order < 0 {
                                    let order = compare(name, "login-keys.svg");
                                    if order == 0 { return 193; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "logout.svg");
                                if order == 0 { return 196; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "noooo.mp3");
                if order == 0 { return 217; }
                if order < 0 {
                    let order = compare(name, "messages.svg");
                    if order == 0 { return 207; }
                    if order < 0 {
                        let order = compare(name, "menu.svg");
                        if order == 0 { return 202; }
                        if order < 0 {
                            let order = compare(name, "menu-dots-horizontal.svg");
                            if order == 0 { return 200; }
                            if order < 0 {
                                let order = compare(name, "maybe.mp3");
                                if order == 0 { return 199; }
                                if order < 0 {
                                    let order = compare(name, "mario_coin.mp3");
                                    if order == 0 { return 198; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "menu-dots-vertical.svg");
                                if order == 0 { return 201; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "messages-outlined.svg");
                            if order == 0 { return 205; }
                            if order < 0 {
                                let order = compare(name, "messages-empty.svg");
                                if order == 0 { return 204; }
                                if order < 0 {
                                    let order = compare(name, "messages-add.svg");
                                    if order == 0 { return 203; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "messages.css");
                                if order == 0 { return 206; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "models/message_formatter.js");
                        if order == 0 { return 212; }
                        if order < 0 {
                            let order = compare(name, "models/client_message.js");
                            if order == 0 { return 210; }
                            if order < 0 {
                                let order = compare(name, "mobile-phone.svg");
                                if order == 0 { return 209; }
                                if order < 0 {
                                    let order = compare(name, "minus.svg");
                                    if order == 0 { return 208; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "models/file_uploader.js");
                                if order == 0 { return 211; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "models/typing_tracker.js");
                            if order == 0 { return 215; }
                            if order < 0 {
                                let order = compare(name, "models/scroll_manager.js");
                                if order == 0 { return 214; }
                                if order < 0 {
                                    let order = compare(name, "models/message_paginator.js");
                                    if order == 0 { return 213; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "nav.css");
                                if order == 0 { return 216; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "ohyeah.mp3");
                    if order == 0 { return 227; }
                    if order < 0 {
                        let order = compare(name, "notification-bell-mentions.svg");
                        if order == 0 { return 222; }
                        if order < 0 {
                            let order = compare(name, "notification-bell-invisible.svg");
                            if order == 0 { return 220; }
                            if order < 0 {
                                let order = compare(name, "notification-bell-everything.svg");
                                if order == 0 { return 219; }
                                if order < 0 {
                                    let order = compare(name, "notification-bell-alert.svg");
                                    if order == 0 { return 218; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "notification-bell-loading.svg");
                                if order == 0 { return 221; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "office.svg");
                            if order == 0 { return 225; }
                            if order < 0 {
                                let order = compare(name, "nyan.mp3");
                                if order == 0 { return 224; }
                                if order < 0 {
                                    let order = compare(name, "notification-bell-nothing.svg");
                                    if order == 0 { return 223; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "ohmy.mp3");
                                if order == 0 { return 226; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "person.svg");
                        if order == 0 { return 232; }
                        if order < 0 {
                            let order = compare(name, "pencil.svg");
                            if order == 0 { return 230; }
                            if order < 0 {
                                let order = compare(name, "password.svg");
                                if order == 0 { return 229; }
                                if order < 0 {
                                    let order = compare(name, "panels.css");
                                    if order == 0 { return 228; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "person-add.svg");
                                if order == 0 { return 231; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "qr-code.svg");
                            if order == 0 { return 234; }
                            if order < 0 {
                                let order = compare(name, "pushit.mp3");
                                if order == 0 { return 233; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "rails-ujs.esm.js");
                                if order == 0 { return 235; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let order = compare(name, "sounds/top.gif");
            if order == 0 { return 276; }
            if order < 0 {
                let order = compare(name, "sounds/56k.gif");
                if order == 0 { return 256; }
                if order < 0 {
                    let order = compare(name, "screenshots/android-dark-mode.png");
                    if order == 0 { return 246; }
                    if order < 0 {
                        let order = compare(name, "rimshot.mp3");
                        if order == 0 { return 241; }
                        if order < 0 {
                            let order = compare(name, "remove.svg");
                            if order == 0 { return 239; }
                            if order < 0 {
                                let order = compare(name, "remove-circle.svg");
                                if order == 0 { return 238; }
                                if order < 0 {
                                    let order = compare(name, "refresh.svg");
                                    if order == 0 { return 237; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "reply.svg");
                                if order == 0 { return 240; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "sax.mp3");
                            if order == 0 { return 244; }
                            if order < 0 {
                                let order = compare(name, "rumble.mp3");
                                if order == 0 { return 243; }
                                if order < 0 {
                                    let order = compare(name, "rollout.mp3");
                                    if order == 0 { return 242; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "screenshots/android-chat.png");
                                if order == 0 { return 245; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "settings.svg");
                        if order == 0 { return 251; }
                        if order < 0 {
                            let order = compare(name, "secret.mp3");
                            if order == 0 { return 249; }
                            if order < 0 {
                                let order = compare(name, "search.svg");
                                if order == 0 { return 248; }
                                if order < 0 {
                                    let order = compare(name, "screenshots/android-sidebar.png");
                                    if order == 0 { return 247; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "separators.css");
                                if order == 0 { return 250; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "sidebar.css");
                            if order == 0 { return 254; }
                            if order < 0 {
                                let order = compare(name, "share.svg");
                                if order == 0 { return 253; }
                                if order < 0 {
                                    let order = compare(name, "sexyback.mp3");
                                    if order == 0 { return 252; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "signup.css");
                                if order == 0 { return 255; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "sounds/drama.webp");
                    if order == 0 { return 266; }
                    if order < 0 {
                        let order = compare(name, "sounds/curb.webp");
                        if order == 0 { return 261; }
                        if order < 0 {
                            let order = compare(name, "sounds/clowntown.webp");
                            if order == 0 { return 259; }
                            if order < 0 {
                                let order = compare(name, "sounds/clowntown.gif");
                                if order == 0 { return 258; }
                                if order < 0 {
                                    let order = compare(name, "sounds/56k.webp");
                                    if order == 0 { return 257; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "sounds/curb.gif");
                                if order == 0 { return 260; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "sounds/donotwant.gif");
                            if order == 0 { return 264; }
                            if order < 0 {
                                let order = compare(name, "sounds/dangerzone.webp");
                                if order == 0 { return 263; }
                                if order < 0 {
                                    let order = compare(name, "sounds/dangerzone.png");
                                    if order == 0 { return 262; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "sounds/donotwant.webp");
                                if order == 0 { return 265; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "sounds/nyan.webp");
                        if order == 0 { return 271; }
                        if order < 0 {
                            let order = compare(name, "sounds/loggins.webp");
                            if order == 0 { return 269; }
                            if order < 0 {
                                let order = compare(name, "sounds/greatjob.webp");
                                if order == 0 { return 268; }
                                if order < 0 {
                                    let order = compare(name, "sounds/greatjob.png");
                                    if order == 0 { return 267; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "sounds/nyan.gif");
                                if order == 0 { return 270; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "sounds/rumble.gif");
                            if order == 0 { return 274; }
                            if order < 0 {
                                let order = compare(name, "sounds/pushit.webp");
                                if order == 0 { return 273; }
                                if order < 0 {
                                    let order = compare(name, "sounds/pushit.gif");
                                    if order == 0 { return 272; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "sounds/rumble.webp");
                                if order == 0 { return 275; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "transfer.svg");
                if order == 0 { return 296; }
                if order < 0 {
                    let order = compare(name, "stimulus-importmap-autoloader.js");
                    if order == 0 { return 286; }
                    if order < 0 {
                        let order = compare(name, "sounds/yay.webp");
                        if order == 0 { return 281; }
                        if order < 0 {
                            let order = compare(name, "sounds/what.webp");
                            if order == 0 { return 279; }
                            if order < 0 {
                                let order = compare(name, "sounds/what.gif");
                                if order == 0 { return 278; }
                                if order < 0 {
                                    let order = compare(name, "sounds/top.webp");
                                    if order == 0 { return 277; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "sounds/yay.png");
                                if order == 0 { return 280; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "spinner.css");
                            if order == 0 { return 284; }
                            if order < 0 {
                                let order = compare(name, "sounds/yeah.webp");
                                if order == 0 { return 283; }
                                if order < 0 {
                                    let order = compare(name, "sounds/yeah.gif");
                                    if order == 0 { return 282; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "stimulus-autoloader.js");
                                if order == 0 { return 285; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "story.mp3");
                        if order == 0 { return 291; }
                        if order < 0 {
                            let order = compare(name, "stimulus.min.js");
                            if order == 0 { return 289; }
                            if order < 0 {
                                let order = compare(name, "stimulus.js");
                                if order == 0 { return 288; }
                                if order < 0 {
                                    let order = compare(name, "stimulus-loading.js");
                                    if order == 0 { return 287; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "stimulus.min.js.map");
                                if order == 0 { return 290; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "tmyk.mp3");
                            if order == 0 { return 294; }
                            if order < 0 {
                                let order = compare(name, "text-options.svg");
                                if order == 0 { return 293; }
                                if order < 0 {
                                    let order = compare(name, "tada.mp3");
                                    if order == 0 { return 292; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "totes.mp3");
                                if order == 0 { return 295; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "utilities.css");
                    if order == 0 { return 306; }
                    if order < 0 {
                        let order = compare(name, "trombone.mp3");
                        if order == 0 { return 301; }
                        if order < 0 {
                            let order = compare(name, "trix.js");
                            if order == 0 { return 299; }
                            if order < 0 {
                                let order = compare(name, "trix.css");
                                if order == 0 { return 298; }
                                if order < 0 {
                                    let order = compare(name, "trash.svg");
                                    if order == 0 { return 297; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "trololo.mp3");
                                if order == 0 { return 300; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "turbo.min.js.map");
                            if order == 0 { return 304; }
                            if order < 0 {
                                let order = compare(name, "turbo.min.js");
                                if order == 0 { return 303; }
                                if order < 0 {
                                    let order = compare(name, "turbo.js");
                                    if order == 0 { return 302; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "unix.mp3");
                                if order == 0 { return 305; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "wups.mp3");
                        if order == 0 { return 311; }
                        if order < 0 {
                            let order = compare(name, "what.mp3");
                            if order == 0 { return 309; }
                            if order < 0 {
                                let order = compare(name, "web.svg");
                                if order == 0 { return 308; }
                                if order < 0 {
                                    let order = compare(name, "vuvuzela.mp3");
                                    if order == 0 { return 307; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "whoomp.mp3");
                                if order == 0 { return 310; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "yeah.mp3");
                            if order == 0 { return 313; }
                            if order < 0 {
                                let order = compare(name, "yay.mp3");
                                if order == 0 { return 312; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "yodel.mp3");
                                if order == 0 { return 314; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

fn asset_public_index(name: const u8[:]) -> i64 {
    let order = compare(name, "/assets/laptop-cf35e6d4.svg");
    if order == 0 { return 157; }
    if order < 0 {
        let order = compare(name, "/assets/controllers/soft_keyboard_controller-be1da837.js");
        if order == 0 { return 78; }
        if order < 0 {
            let order = compare(name, "/assets/buttons-c7d39fd4.css");
            if order == 0 { return 39; }
            if order < 0 {
                let order = compare(name, "/assets/art-ed709d32.svg");
                if order == 0 { return 19; }
                if order < 0 {
                    let order = compare(name, "/assets/activestorage-f9e46063.js");
                    if order == 0 { return 10; }
                    if order < 0 {
                        let order = compare(name, "/assets/actioncable-ac25813f.js");
                        if order == 0 { return 5; }
                        if order < 0 {
                            let order = compare(name, "/assets/_reset-9c3efd7b.css");
                            if order == 0 { return 2; }
                            if order < 0 {
                                let order = compare(name, "/assets/@rails--request-3fc8489d.js");
                                if order == 0 { return 1; }
                                if order < 0 {
                                    let order = compare(name, "/assets/56k-67359aa6.mp3");
                                    if order == 0 { return 0; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/action_cable-5212cfee.js");
                                if order == 0 { return 3; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/actiontext-c9c6c481.js");
                            if order == 0 { return 8; }
                            if order < 0 {
                                let order = compare(name, "/assets/actiontext-7b8d51ea.css");
                                if order == 0 { return 6; }
                                if order < 0 {
                                    let order = compare(name, "/assets/actioncable.esm-e0ec9819.js");
                                    if order == 0 { return 4; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/actiontext.esm-c376325e.js");
                                if order == 0 { return 7; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/application-a54c74a7.js");
                        if order == 0 { return 14; }
                        if order < 0 {
                            let order = compare(name, "/assets/alert-b937985b.svg");
                            if order == 0 { return 12; }
                            if order < 0 {
                                let order = compare(name, "/assets/add-f232d8a6.svg");
                                if order == 0 { return 11; }
                                if order < 0 {
                                    let order = compare(name, "/assets/activestorage.esm-81bb34bc.js");
                                    if order == 0 { return 9; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/animation-bcdb4bab.css");
                                if order == 0 { return 13; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/arrow-right-8f3eb40d.svg");
                            if order == 0 { return 17; }
                            if order < 0 {
                                let order = compare(name, "/assets/arrow-left-abe40556.svg");
                                if order == 0 { return 16; }
                                if order < 0 {
                                    let order = compare(name, "/assets/arrow-down-3f174d76.svg");
                                    if order == 0 { return 15; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/arrow-up-f96b3895.svg");
                                if order == 0 { return 18; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/boosts-da4032a8.css");
                    if order == 0 { return 29; }
                    if order < 0 {
                        let order = compare(name, "/assets/base-637a0ec8.css");
                        if order == 0 { return 24; }
                        if order < 0 {
                            let order = compare(name, "/assets/avatars-279376ab.css");
                            if order == 0 { return 22; }
                            if order < 0 {
                                let order = compare(name, "/assets/autocomplete-9de8c93f.css");
                                if order == 0 { return 21; }
                                if order < 0 {
                                    let order = compare(name, "/assets/attachment-8bcccab0.svg");
                                    if order == 0 { return 20; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/ballmer-055893e5.mp3");
                                if order == 0 { return 23; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/bio-567a6005.svg");
                            if order == 0 { return 27; }
                            if order < 0 {
                                let order = compare(name, "/assets/bezos-ed56ef09.mp3");
                                if order == 0 { return 26; }
                                if order < 0 {
                                    let order = compare(name, "/assets/bell-4dd04376.mp3");
                                    if order == 0 { return 25; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/boost-4a7bab66.svg");
                                if order == 0 { return 28; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/browsers/edge-352f198a.svg");
                        if order == 0 { return 34; }
                        if order < 0 {
                            let order = compare(name, "/assets/browsers/android-196a24ef.svg");
                            if order == 0 { return 32; }
                            if order < 0 {
                                let order = compare(name, "/assets/broom-13d30a95.svg");
                                if order == 0 { return 31; }
                                if order < 0 {
                                    let order = compare(name, "/assets/bot-8a69692e.svg");
                                    if order == 0 { return 30; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/browsers/chrome-196a24ef.svg");
                                if order == 0 { return 33; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/browsers/safari-0b7b9bbc.svg");
                            if order == 0 { return 37; }
                            if order < 0 {
                                let order = compare(name, "/assets/browsers/opera-0f156483.svg");
                                if order == 0 { return 36; }
                                if order < 0 {
                                    let order = compare(name, "/assets/browsers/firefox-57046321.svg");
                                    if order == 0 { return 35; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/bueller-edbffb89.mp3");
                                if order == 0 { return 38; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "/assets/controllers/element_removal_controller-4526910a.js");
                if order == 0 { return 59; }
                if order < 0 {
                    let order = compare(name, "/assets/common-file-text-9043d980.svg");
                    if order == 0 { return 49; }
                    if order < 0 {
                        let order = compare(name, "/assets/check-7897ff7e.svg");
                        if order == 0 { return 44; }
                        if order < 0 {
                            let order = compare(name, "/assets/campfire-icon-3d9986c5.png");
                            if order == 0 { return 42; }
                            if order < 0 {
                                let order = compare(name, "/assets/camera-927323b8.svg");
                                if order == 0 { return 41; }
                                if order < 0 {
                                    let order = compare(name, "/assets/butts-6774d8a3.mp3");
                                    if order == 0 { return 40; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/cancel-c6dfeb78.svg");
                                if order == 0 { return 43; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/colorize-eb391ca0.css");
                            if order == 0 { return 47; }
                            if order < 0 {
                                let order = compare(name, "/assets/code-333ae548.css");
                                if order == 0 { return 46; }
                                if order < 0 {
                                    let order = compare(name, "/assets/clowntown-880ab480.mp3");
                                    if order == 0 { return 45; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/colors-aee62523.css");
                                if order == 0 { return 48; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/controllers/badge_dot_controller-e0d733c8.js");
                        if order == 0 { return 54; }
                        if order < 0 {
                            let order = compare(name, "/assets/controllers/auto_submit_controller-ee52d396.js");
                            if order == 0 { return 52; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/application-f004202c.js");
                                if order == 0 { return 51; }
                                if order < 0 {
                                    let order = compare(name, "/assets/composer-e490638a.css");
                                    if order == 0 { return 50; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/autocomplete_controller-eaf5b07d.js");
                                if order == 0 { return 53; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/controllers/copy_to_clipboard_controller-a4928c72.js");
                            if order == 0 { return 57; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/composer_controller-73c33f9f.js");
                                if order == 0 { return 56; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/boost_delete_controller-29fd1686.js");
                                    if order == 0 { return 55; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/drop_target_controller-3a205782.js");
                                if order == 0 { return 58; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/controllers/presence_controller-28f14aad.js");
                    if order == 0 { return 69; }
                    if order < 0 {
                        let order = compare(name, "/assets/controllers/local_time_controller-7daf3d0c.js");
                        if order == 0 { return 64; }
                        if order < 0 {
                            let order = compare(name, "/assets/controllers/index-594ba2fb.js");
                            if order == 0 { return 62; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/form_controller-6f3d64db.js");
                                if order == 0 { return 61; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/filter_controller-ca9769d5.js");
                                    if order == 0 { return 60; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/lightbox_controller-98fc07ca.js");
                                if order == 0 { return 63; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/controllers/notifications_controller-746d0662.js");
                            if order == 0 { return 67; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/messages_controller-3d90944a.js");
                                if order == 0 { return 66; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/maintain_scroll_controller-1debbbfb.js");
                                    if order == 0 { return 65; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/popup_controller-9f8ea824.js");
                                if order == 0 { return 68; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/controllers/rooms_list_controller-8fe7485c.js");
                        if order == 0 { return 74; }
                        if order < 0 {
                            let order = compare(name, "/assets/controllers/refresh_room_controller-4e4b6014.js");
                            if order == 0 { return 72; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/read_rooms_controller-8245522a.js");
                                if order == 0 { return 71; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/pwa_install_controller-3fe3fc5e.js");
                                    if order == 0 { return 70; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/reply_controller-278bb9cc.js");
                                if order == 0 { return 73; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/controllers/search_results_controller-aab46974.js");
                            if order == 0 { return 76; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/scroll_into_view_controller-8a0bc733.js");
                                if order == 0 { return 75; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/sessions_controller-a9fdfe3d.js");
                                if order == 0 { return 77; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let order = compare(name, "/assets/gogogo-f091ebbc.mp3");
            if order == 0 { return 118; }
            if order < 0 {
                let order = compare(name, "/assets/default-bot-avatar-de1d12f7.svg");
                if order == 0 { return 98; }
                if order < 0 {
                    let order = compare(name, "/assets/copy-paste-4c379063.svg");
                    if order == 0 { return 88; }
                    if order < 0 {
                        let order = compare(name, "/assets/controllers/turbo_streaming_controller-04b85a80.js");
                        if order == 0 { return 83; }
                        if order < 0 {
                            let order = compare(name, "/assets/controllers/toggle_class_controller-b67fa681.js");
                            if order == 0 { return 81; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/sound_controller-d3e5656e.js");
                                if order == 0 { return 80; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/sorted_list_controller-9f9ae485.js");
                                    if order == 0 { return 79; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/turbo_frame_controller-9f4f722f.js");
                                if order == 0 { return 82; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/controllers/upload_preview_controller-9b8b26bb.js");
                            if order == 0 { return 86; }
                            if order < 0 {
                                let order = compare(name, "/assets/controllers/unfurl_controller-4a868f9a.js");
                                if order == 0 { return 85; }
                                if order < 0 {
                                    let order = compare(name, "/assets/controllers/typing_notifications_controller-86906ab9.js");
                                    if order == 0 { return 84; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/controllers/web_share_controller-f7236b6f.js");
                                if order == 0 { return 87; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/dadgummit-6c84151f.mp3");
                        if order == 0 { return 93; }
                        if order < 0 {
                            let order = compare(name, "/assets/crown-00d190cb.svg");
                            if order == 0 { return 91; }
                            if order < 0 {
                                let order = compare(name, "/assets/crickets-b50f1da0.mp3");
                                if order == 0 { return 90; }
                                if order < 0 {
                                    let order = compare(name, "/assets/cottoneyejoe-39c980e8.mp3");
                                    if order == 0 { return 89; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/curb-f9327cfc.mp3");
                                if order == 0 { return 92; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/deeper-c9fe70a0.mp3");
                            if order == 0 { return 96; }
                            if order < 0 {
                                let order = compare(name, "/assets/danielsan-0815085a.mp3");
                                if order == 0 { return 95; }
                                if order < 0 {
                                    let order = compare(name, "/assets/dangerzone-7382b27e.mp3");
                                    if order == 0 { return 94; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/default-avatar-1ee67b00.svg");
                                if order == 0 { return 97; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/external/install-f762b3be.svg");
                    if order == 0 { return 108; }
                    if order < 0 {
                        let order = compare(name, "/assets/email-6c595bc5.svg");
                        if order == 0 { return 103; }
                        if order < 0 {
                            let order = compare(name, "/assets/download-04029899.svg");
                            if order == 0 { return 101; }
                            if order < 0 {
                                let order = compare(name, "/assets/donotwant-fa71a459.mp3");
                                if order == 0 { return 100; }
                                if order < 0 {
                                    let order = compare(name, "/assets/disclosure-26d63471.svg");
                                    if order == 0 { return 99; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/drama-92fb52d2.mp3");
                                if order == 0 { return 102; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/external/gear-50e77d2b.svg");
                            if order == 0 { return 106; }
                            if order < 0 {
                                let order = compare(name, "/assets/everyone-4ca1d460.svg");
                                if order == 0 { return 105; }
                                if order < 0 {
                                    let order = compare(name, "/assets/embeds-c20d0a3a.css");
                                    if order == 0 { return 104; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/external/install-edge-0b7cd918.svg");
                                if order == 0 { return 107; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/filters-8a4d63ed.css");
                        if order == 0 { return 113; }
                        if order < 0 {
                            let order = compare(name, "/assets/external/switch-eec22a2d.svg");
                            if order == 0 { return 111; }
                            if order < 0 {
                                let order = compare(name, "/assets/external/sliders-3979a007.svg");
                                if order == 0 { return 110; }
                                if order < 0 {
                                    let order = compare(name, "/assets/external/share-f9d3e998.svg");
                                    if order == 0 { return 109; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/external/web-24ffe636.svg");
                                if order == 0 { return 112; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/glados-f033ed9e.mp3");
                            if order == 0 { return 116; }
                            if order < 0 {
                                let order = compare(name, "/assets/flawless-678d1f3c.mp3");
                                if order == 0 { return 115; }
                                if order < 0 {
                                    let order = compare(name, "/assets/flash-a561c1e5.css");
                                    if order == 0 { return 114; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/globe-8c54d23b.svg");
                                if order == 0 { return 117; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "/assets/initializers/highlight-5bd558f1.js");
                if order == 0 { return 138; }
                if order < 0 {
                    let order = compare(name, "/assets/helpers/turbo_helpers-a3c01462.js");
                    if order == 0 { return 128; }
                    if order < 0 {
                        let order = compare(name, "/assets/help-circle-1bb1a839.svg");
                        if order == 0 { return 122; }
                        if order < 0 {
                            let order = compare(name, "/assets/guarantee-8e639fbb.mp3");
                            if order == 0 { return 121; }
                            if order < 0 {
                                let order = compare(name, "/assets/greyjoy-dcb0e786.mp3");
                                if order == 0 { return 120; }
                                if order < 0 {
                                    let order = compare(name, "/assets/greatjob-7d6aada2.mp3");
                                    if order == 0 { return 119; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/help-a18b47fc.svg");
                                if order == 0 { return 123; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/helpers/string_helpers-40941ba8.js");
                            if order == 0 { return 126; }
                            if order < 0 {
                                let order = compare(name, "/assets/helpers/navigator_helpers-3c9f4c31.js");
                                if order == 0 { return 125; }
                                if order < 0 {
                                    let order = compare(name, "/assets/helpers/dom_helpers-0f234176.js");
                                    if order == 0 { return 124; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/helpers/timing_helpers-94d95529.js");
                                if order == 0 { return 127; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/horror-5181b7e4.mp3");
                        if order == 0 { return 133; }
                        if order < 0 {
                            let order = compare(name, "/assets/honk-9c336a89.mp3");
                            if order == 0 { return 131; }
                            if order < 0 {
                                let order = compare(name, "/assets/highlight.js/core-4e141f64.js");
                                if order == 0 { return 130; }
                                if order < 0 {
                                    let order = compare(name, "/assets/heygirl-b9a85600.mp3");
                                    if order == 0 { return 129; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/horn-efb0f714.mp3");
                                if order == 0 { return 132; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/initializers/autocomplete-ba9abe45.js");
                            if order == 0 { return 136; }
                            if order < 0 {
                                let order = compare(name, "/assets/inconceivable-c8811768.mp3");
                                if order == 0 { return 135; }
                                if order < 0 {
                                    let order = compare(name, "/assets/incoming-0621d199.mp3");
                                    if order == 0 { return 134; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/initializers/current-3a3b90da.js");
                                if order == 0 { return 137; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/languages/java-95f3a30f.js");
                    if order == 0 { return 148; }
                    if order < 0 {
                        let order = compare(name, "/assets/key-82330955.svg");
                        if order == 0 { return 143; }
                        if order < 0 {
                            let order = compare(name, "/assets/inputs-9e58a07c.css");
                            if order == 0 { return 141; }
                            if order < 0 {
                                let order = compare(name, "/assets/initializers/rich_text-f451a05e.js");
                                if order == 0 { return 140; }
                                if order < 0 {
                                    let order = compare(name, "/assets/initializers/index-d2bbfae4.js");
                                    if order == 0 { return 139; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/install-edge-0b7cd918.svg");
                                if order == 0 { return 142; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/languages/diff-94a335fe.js");
                            if order == 0 { return 146; }
                            if order < 0 {
                                let order = compare(name, "/assets/languages/css-a7f2e40b.js");
                                if order == 0 { return 145; }
                                if order < 0 {
                                    let order = compare(name, "/assets/languages/bash-13136668.js");
                                    if order == 0 { return 144; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/languages/go-10465864.js");
                                if order == 0 { return 147; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/languages/rust-d48f93d8.js");
                        if order == 0 { return 153; }
                        if order < 0 {
                            let order = compare(name, "/assets/languages/python-8f48fd1a.js");
                            if order == 0 { return 151; }
                            if order < 0 {
                                let order = compare(name, "/assets/languages/json-60184e1b.js");
                                if order == 0 { return 150; }
                                if order < 0 {
                                    let order = compare(name, "/assets/languages/javascript-18eb0dd8.js");
                                    if order == 0 { return 149; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/languages/ruby-287ccd0f.js");
                                if order == 0 { return 152; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/languages/xml-fa7f1eda.js");
                            if order == 0 { return 155; }
                            if order < 0 {
                                let order = compare(name, "/assets/languages/sql-642be05a.js");
                                if order == 0 { return 154; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lanyard-945079e9.svg");
                                if order == 0 { return 156; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        let order = compare(name, "/assets/rails-ujs.esm-e925103b.js");
        if order == 0 { return 235; }
        if order < 0 {
            let order = compare(name, "/assets/makeitso-f6e530b1.mp3");
            if order == 0 { return 197; }
            if order < 0 {
                let order = compare(name, "/assets/lib/autocomplete/helpers-651308b9.js");
                if order == 0 { return 177; }
                if order < 0 {
                    let order = compare(name, "/assets/lexxy.js-9130cdde.gz");
                    if order == 0 { return 166; }
                    if order < 0 {
                        let order = compare(name, "/assets/lexxy-cf040c43.js.map");
                        if order == 0 { return 167; }
                        if order < 0 {
                            let order = compare(name, "/assets/lexxy-2876c58e.css");
                            if order == 0 { return 163; }
                            if order < 0 {
                                let order = compare(name, "/assets/letitgo-bc89591d.mp3");
                                if order == 0 { return 159; }
                                if order < 0 {
                                    let order = compare(name, "/assets/layout-ff6ddfc6.css");
                                    if order == 0 { return 158; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lexxy-a21f41d4.js");
                                if order == 0 { return 164; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/lexxy-variables-3fef4323.css");
                            if order == 0 { return 162; }
                            if order < 0 {
                                let order = compare(name, "/assets/lexxy-editor-2d5c7ebe.css");
                                if order == 0 { return 161; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lexxy-content-0ff2f961.css");
                                    if order == 0 { return 160; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lexxy.js-380cb9c9.br");
                                if order == 0 { return 165; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/lib/autocomplete/base_autocomplete_handler-96e7e419.js");
                        if order == 0 { return 172; }
                        if order < 0 {
                            let order = compare(name, "/assets/lexxy.min.js-56322c4c.gz");
                            if order == 0 { return 170; }
                            if order < 0 {
                                let order = compare(name, "/assets/lexxy.min.js-02328003.br");
                                if order == 0 { return 169; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lexxy.min-68f38983.js");
                                    if order == 0 { return 168; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lib/autocomplete/autocomplete_handler-becd1e1a.js");
                                if order == 0 { return 171; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/lib/autocomplete/custom_elements/suggestion_option-ac7846b3.js");
                            if order == 0 { return 175; }
                            if order < 0 {
                                let order = compare(name, "/assets/lib/autocomplete/constants-17c2858b.js");
                                if order == 0 { return 174; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lib/autocomplete/collection-3e251a0e.js");
                                    if order == 0 { return 173; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lib/autocomplete/custom_elements/suggestion_select-f0045305.js");
                                if order == 0 { return 176; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/lifebuoy-f31f26aa.svg");
                    if order == 0 { return 187; }
                    if order < 0 {
                        let order = compare(name, "/assets/lib/autocomplete/suggestion_results_controller-91405749.js");
                        if order == 0 { return 182; }
                        if order < 0 {
                            let order = compare(name, "/assets/lib/autocomplete/suggestion_context-b265ffb4.js");
                            if order == 0 { return 180; }
                            if order < 0 {
                                let order = compare(name, "/assets/lib/autocomplete/selection-862705bf.js");
                                if order == 0 { return 179; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lib/autocomplete/renderer-5caf6120.js");
                                    if order == 0 { return 178; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lib/autocomplete/suggestion_controller-10624c40.js");
                                if order == 0 { return 181; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/lib/rich_text/campfire_extension-f62f017b.js");
                            if order == 0 { return 185; }
                            if order < 0 {
                                let order = compare(name, "/assets/lib/cookie-76006835.js");
                                if order == 0 { return 184; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lib/autocomplete/utils-296fb278.js");
                                    if order == 0 { return 183; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lib/rich_text/cite_node-b4d2b89a.js");
                                if order == 0 { return 186; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/loggins-63aac7af.mp3");
                        if order == 0 { return 192; }
                        if order < 0 {
                            let order = compare(name, "/assets/live-550f1f88.mp3");
                            if order == 0 { return 190; }
                            if order < 0 {
                                let order = compare(name, "/assets/link-e546a5df.svg");
                                if order == 0 { return 189; }
                                if order < 0 {
                                    let order = compare(name, "/assets/lightbox-af496d39.css");
                                    if order == 0 { return 188; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/lock-7cdf4b3d.svg");
                                if order == 0 { return 191; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/logos/app-icon-a6fa894e.png");
                            if order == 0 { return 195; }
                            if order < 0 {
                                let order = compare(name, "/assets/logos/app-icon-192-646b105a.png");
                                if order == 0 { return 194; }
                                if order < 0 {
                                    let order = compare(name, "/assets/login-keys-df926967.svg");
                                    if order == 0 { return 193; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/logout-a6131db1.svg");
                                if order == 0 { return 196; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "/assets/noooo-c68a85f4.mp3");
                if order == 0 { return 217; }
                if order < 0 {
                    let order = compare(name, "/assets/messages-outlined-87ff0331.svg");
                    if order == 0 { return 205; }
                    if order < 0 {
                        let order = compare(name, "/assets/menu-dots-vertical-c247e3cc.svg");
                        if order == 0 { return 201; }
                        if order < 0 {
                            let order = compare(name, "/assets/menu-5462dfd3.svg");
                            if order == 0 { return 202; }
                            if order < 0 {
                                let order = compare(name, "/assets/maybe-4a638e83.mp3");
                                if order == 0 { return 199; }
                                if order < 0 {
                                    let order = compare(name, "/assets/mario_coin-556717d1.mp3");
                                    if order == 0 { return 198; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/menu-dots-horizontal-f6a5d793.svg");
                                if order == 0 { return 200; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/messages-c5485fef.css");
                            if order == 0 { return 206; }
                            if order < 0 {
                                let order = compare(name, "/assets/messages-add-d229e6c2.svg");
                                if order == 0 { return 203; }
                                if order < 0 {
                                    let order = compare(name, "/assets/messages-9395d503.svg");
                                    if order == 0 { return 207; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/messages-empty-84c8fd41.svg");
                                if order == 0 { return 204; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/models/message_formatter-f39a0c5d.js");
                        if order == 0 { return 212; }
                        if order < 0 {
                            let order = compare(name, "/assets/models/client_message-de3c07cf.js");
                            if order == 0 { return 210; }
                            if order < 0 {
                                let order = compare(name, "/assets/mobile-phone-d0d2301d.svg");
                                if order == 0 { return 209; }
                                if order < 0 {
                                    let order = compare(name, "/assets/minus-b31a1093.svg");
                                    if order == 0 { return 208; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/models/file_uploader-09a18428.js");
                                if order == 0 { return 211; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/models/typing_tracker-42a444a5.js");
                            if order == 0 { return 215; }
                            if order < 0 {
                                let order = compare(name, "/assets/models/scroll_manager-ed559629.js");
                                if order == 0 { return 214; }
                                if order < 0 {
                                    let order = compare(name, "/assets/models/message_paginator-b79013e3.js");
                                    if order == 0 { return 213; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/nav-05e7183a.css");
                                if order == 0 { return 216; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/ohyeah-48506f41.mp3");
                    if order == 0 { return 227; }
                    if order < 0 {
                        let order = compare(name, "/assets/notification-bell-mentions-945d1b91.svg");
                        if order == 0 { return 222; }
                        if order < 0 {
                            let order = compare(name, "/assets/notification-bell-invisible-8b495073.svg");
                            if order == 0 { return 220; }
                            if order < 0 {
                                let order = compare(name, "/assets/notification-bell-everything-cde41b14.svg");
                                if order == 0 { return 219; }
                                if order < 0 {
                                    let order = compare(name, "/assets/notification-bell-alert-b467cde7.svg");
                                    if order == 0 { return 218; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/notification-bell-loading-7533ce55.svg");
                                if order == 0 { return 221; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/office-69ba5668.svg");
                            if order == 0 { return 225; }
                            if order < 0 {
                                let order = compare(name, "/assets/nyan-1fe5c553.mp3");
                                if order == 0 { return 224; }
                                if order < 0 {
                                    let order = compare(name, "/assets/notification-bell-nothing-d8096c76.svg");
                                    if order == 0 { return 223; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/ohmy-189dd829.mp3");
                                if order == 0 { return 226; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/person-da193438.svg");
                        if order == 0 { return 232; }
                        if order < 0 {
                            let order = compare(name, "/assets/pencil-cf9d28aa.svg");
                            if order == 0 { return 230; }
                            if order < 0 {
                                let order = compare(name, "/assets/password-0896da4e.svg");
                                if order == 0 { return 229; }
                                if order < 0 {
                                    let order = compare(name, "/assets/panels-af44ec6d.css");
                                    if order == 0 { return 228; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/person-add-1432b76b.svg");
                                if order == 0 { return 231; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/qr-code-dac3b273.svg");
                            if order == 0 { return 234; }
                            if order < 0 {
                                let order = compare(name, "/assets/pushit-f43f90a7.mp3");
                                if order == 0 { return 233; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/rails-ujs-20eaf715.js");
                                if order == 0 { return 236; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        } else {
            let order = compare(name, "/assets/sounds/top-15f70a0c.gif");
            if order == 0 { return 276; }
            if order < 0 {
                let order = compare(name, "/assets/sounds/56k-1567db5b.webp");
                if order == 0 { return 257; }
                if order < 0 {
                    let order = compare(name, "/assets/screenshots/android-dark-mode-e43dcf59.png");
                    if order == 0 { return 246; }
                    if order < 0 {
                        let order = compare(name, "/assets/rimshot-66c3332b.mp3");
                        if order == 0 { return 241; }
                        if order < 0 {
                            let order = compare(name, "/assets/remove-circle-384c618c.svg");
                            if order == 0 { return 238; }
                            if order < 0 {
                                let order = compare(name, "/assets/remove-0e7a045d.svg");
                                if order == 0 { return 239; }
                                if order < 0 {
                                    let order = compare(name, "/assets/refresh-249f0509.svg");
                                    if order == 0 { return 237; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/reply-edb77e33.svg");
                                if order == 0 { return 240; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/sax-9e7841a8.mp3");
                            if order == 0 { return 244; }
                            if order < 0 {
                                let order = compare(name, "/assets/rumble-7b5d6e4f.mp3");
                                if order == 0 { return 243; }
                                if order < 0 {
                                    let order = compare(name, "/assets/rollout-3a826ae4.mp3");
                                    if order == 0 { return 242; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/screenshots/android-chat-f8b923c9.png");
                                if order == 0 { return 245; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/settings-aee56972.svg");
                        if order == 0 { return 251; }
                        if order < 0 {
                            let order = compare(name, "/assets/secret-9f61e3b5.mp3");
                            if order == 0 { return 249; }
                            if order < 0 {
                                let order = compare(name, "/assets/search-5f29565f.svg");
                                if order == 0 { return 248; }
                                if order < 0 {
                                    let order = compare(name, "/assets/screenshots/android-sidebar-e9d2b49f.png");
                                    if order == 0 { return 247; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/separators-172b3ab8.css");
                                if order == 0 { return 250; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/sidebar-0be58db9.css");
                            if order == 0 { return 254; }
                            if order < 0 {
                                let order = compare(name, "/assets/share-bf28da4f.svg");
                                if order == 0 { return 253; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sexyback-ec0cf66f.mp3");
                                    if order == 0 { return 252; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/signup-6e02d591.css");
                                if order == 0 { return 255; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/sounds/drama-b398c916.webp");
                    if order == 0 { return 266; }
                    if order < 0 {
                        let order = compare(name, "/assets/sounds/curb-b74cab9f.webp");
                        if order == 0 { return 261; }
                        if order < 0 {
                            let order = compare(name, "/assets/sounds/clowntown-fa123df7.gif");
                            if order == 0 { return 258; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/clowntown-1670db9e.webp");
                                if order == 0 { return 259; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/56k-22d60d09.gif");
                                    if order == 0 { return 256; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/sounds/curb-0c6f596b.gif");
                                if order == 0 { return 260; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/sounds/donotwant-c19843b2.gif");
                            if order == 0 { return 264; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/dangerzone-60067535.png");
                                if order == 0 { return 262; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/dangerzone-0e0f0d09.webp");
                                    if order == 0 { return 263; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/sounds/donotwant-d29fb6fb.webp");
                                if order == 0 { return 265; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/sounds/nyan-995f5ada.gif");
                        if order == 0 { return 270; }
                        if order < 0 {
                            let order = compare(name, "/assets/sounds/loggins-a40a75e6.webp");
                            if order == 0 { return 269; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/greatjob-d65f324c.png");
                                if order == 0 { return 267; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/greatjob-99af483c.webp");
                                    if order == 0 { return 268; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/sounds/nyan-8cc577e4.webp");
                                if order == 0 { return 271; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/sounds/rumble-5ddb8536.gif");
                            if order == 0 { return 274; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/pushit-599fd1e2.gif");
                                if order == 0 { return 272; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/pushit-05915cda.webp");
                                    if order == 0 { return 273; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/sounds/rumble-c4fc52a9.webp");
                                if order == 0 { return 275; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            } else {
                let order = compare(name, "/assets/transfer-3ec4f61b.svg");
                if order == 0 { return 296; }
                if order < 0 {
                    let order = compare(name, "/assets/stimulus-d59b3b7f.js");
                    if order == 0 { return 288; }
                    if order < 0 {
                        let order = compare(name, "/assets/sounds/yay-914d17c4.webp");
                        if order == 0 { return 281; }
                        if order < 0 {
                            let order = compare(name, "/assets/sounds/what-5ff77085.gif");
                            if order == 0 { return 278; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/what-02690db4.webp");
                                if order == 0 { return 279; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/top-cc086a68.webp");
                                    if order == 0 { return 277; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/sounds/yay-6d9d9620.png");
                                if order == 0 { return 280; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/spinner-5a118f25.css");
                            if order == 0 { return 284; }
                            if order < 0 {
                                let order = compare(name, "/assets/sounds/yeah-886795b2.webp");
                                if order == 0 { return 283; }
                                if order < 0 {
                                    let order = compare(name, "/assets/sounds/yeah-7b10b5f7.gif");
                                    if order == 0 { return 282; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/stimulus-autoloader-9d447422.js");
                                if order == 0 { return 285; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/story-0665aaac.mp3");
                        if order == 0 { return 291; }
                        if order < 0 {
                            let order = compare(name, "/assets/stimulus.min-2395e199.js.map");
                            if order == 0 { return 290; }
                            if order < 0 {
                                let order = compare(name, "/assets/stimulus-loading-1fc53fe7.js");
                                if order == 0 { return 287; }
                                if order < 0 {
                                    let order = compare(name, "/assets/stimulus-importmap-autoloader-64cc03e1.js");
                                    if order == 0 { return 286; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/stimulus.min-4b1e420e.js");
                                if order == 0 { return 289; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/tmyk-035cbb8b.mp3");
                            if order == 0 { return 294; }
                            if order < 0 {
                                let order = compare(name, "/assets/text-options-055e0d16.svg");
                                if order == 0 { return 293; }
                                if order < 0 {
                                    let order = compare(name, "/assets/tada-6500487f.mp3");
                                    if order == 0 { return 292; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/totes-665011c8.mp3");
                                if order == 0 { return 295; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                } else {
                    let order = compare(name, "/assets/utilities-e2f32466.css");
                    if order == 0 { return 306; }
                    if order < 0 {
                        let order = compare(name, "/assets/trombone-3cbeabc3.mp3");
                        if order == 0 { return 301; }
                        if order < 0 {
                            let order = compare(name, "/assets/trix-65afdb1d.css");
                            if order == 0 { return 298; }
                            if order < 0 {
                                let order = compare(name, "/assets/trix-4bf79781.js");
                                if order == 0 { return 299; }
                                if order < 0 {
                                    let order = compare(name, "/assets/trash-708c7eb2.svg");
                                    if order == 0 { return 297; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/trololo-d7f880d7.mp3");
                                if order == 0 { return 300; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/turbo.min-5f3b7fda.js.map");
                            if order == 0 { return 304; }
                            if order < 0 {
                                let order = compare(name, "/assets/turbo.min-3a2e143f.js");
                                if order == 0 { return 303; }
                                if order < 0 {
                                    let order = compare(name, "/assets/turbo-a1e3a50a.js");
                                    if order == 0 { return 302; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/unix-bb19b65d.mp3");
                                if order == 0 { return 305; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    } else {
                        let order = compare(name, "/assets/wups-fbad935c.mp3");
                        if order == 0 { return 311; }
                        if order < 0 {
                            let order = compare(name, "/assets/what-880c5f29.mp3");
                            if order == 0 { return 309; }
                            if order < 0 {
                                let order = compare(name, "/assets/web-e179f247.svg");
                                if order == 0 { return 308; }
                                if order < 0 {
                                    let order = compare(name, "/assets/vuvuzela-d177cb0f.mp3");
                                    if order == 0 { return 307; }
                                    if order < 0 {
                                        return -1;
                                    } else {
                                        return -1;
                                    }
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/whoomp-f21c3c43.mp3");
                                if order == 0 { return 310; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        } else {
                            let order = compare(name, "/assets/yeah-71e3371e.mp3");
                            if order == 0 { return 313; }
                            if order < 0 {
                                let order = compare(name, "/assets/yay-1fae7a37.mp3");
                                if order == 0 { return 312; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            } else {
                                let order = compare(name, "/assets/yodel-b14597bb.mp3");
                                if order == 0 { return 314; }
                                if order < 0 {
                                    return -1;
                                } else {
                                    return -1;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

fn asset_filename(index: i64) -> const u8[:] {
    let data = "56k-67359aa6.mp3@rails--request-3fc8489d.js_reset-9c3efd7b.cssaction_cable-5212cfee.jsactioncable.esm-e0ec9819.jsactioncable-ac25813f.jsactiontext-7b8d51ea.cssactiontext.esm-c376325e.jsactiontext-c9c6c481.jsactivestorage.esm-81bb34bc.jsactivestorage-f9e46063.jsadd-f232d8a6.svgalert-b937985b.svganimation-bcdb4bab.cssapplication-a54c74a7.jsarrow-down-3f174d76.svgarrow-left-abe40556.svgarrow-right-8f3eb40d.svgarrow-up-f96b3895.svgart-ed709d32.svgattachment-8bcccab0.svgautocomplete-9de8c93f.cssavatars-279376ab.cssballmer-055893e5.mp3base-637a0ec8.cssbell-4dd04376.mp3bezos-ed56ef09.mp3bio-567a6005.svgboost-4a7bab66.svgboosts-da4032a8.cssbot-8a69692e.svgbroom-13d30a95.svgbrowsers/android-196a24ef.svgbrowsers/chrome-196a24ef.svgbrowsers/edge-352f198a.svgbrowsers/firefox-57046321.svgbrowsers/opera-0f156483.svgbrowsers/safari-0b7b9bbc.svgbueller-edbffb89.mp3buttons-c7d39fd4.cssbutts-6774d8a3.mp3camera-927323b8.svgcampfire-icon-3d9986c5.pngcancel-c6dfeb78.svgcheck-7897ff7e.svgclowntown-880ab480.mp3code-333ae548.csscolorize-eb391ca0.csscolors-aee62523.csscommon-file-text-9043d980.svgcomposer-e490638a.csscontrollers/application-f004202c.jscontrollers/auto_submit_controller-ee52d396.jscontrollers/autocomplete_controller-eaf5b07d.jscontrollers/badge_dot_controller-e0d733c8.jscontrollers/boost_delete_controller-29fd1686.jscontrollers/composer_controller-73c33f9f.jscontrollers/copy_to_clipboard_controller-a4928c72.jscontrollers/drop_target_controller-3a205782.jscontrollers/element_removal_controller-4526910a.jscontrollers/filter_controller-ca9769d5.jscontrollers/form_controller-6f3d64db.jscontrollers/index-594ba2fb.jscontrollers/lightbox_controller-98fc07ca.jscontrollers/local_time_controller-7daf3d0c.jscontrollers/maintain_scroll_controller-1debbbfb.jscontrollers/messages_controller-3d90944a.jscontrollers/notifications_controller-746d0662.jscontrollers/popup_controller-9f8ea824.jscontrollers/presence_controller-28f14aad.jscontrollers/pwa_install_controller-3fe3fc5e.jscontrollers/read_rooms_controller-8245522a.jscontrollers/refresh_room_controller-4e4b6014.jscontrollers/reply_controller-278bb9cc.jscontrollers/rooms_list_controller-8fe7485c.jscontrollers/scroll_into_view_controller-8a0bc733.jscontrollers/search_results_controller-aab46974.jscontrollers/sessions_controller-a9fdfe3d.jscontrollers/soft_keyboard_controller-be1da837.jscontrollers/sorted_list_controller-9f9ae485.jscontrollers/sound_controller-d3e5656e.jscontrollers/toggle_class_controller-b67fa681.jscontrollers/turbo_frame_controller-9f4f722f.jscontrollers/turbo_streaming_controller-04b85a80.jscontrollers/typing_notifications_controller-86906ab9.jscontrollers/unfurl_controller-4a868f9a.jscontrollers/upload_preview_controller-9b8b26bb.jscontrollers/web_share_controller-f7236b6f.jscopy-paste-4c379063.svgcottoneyejoe-39c980e8.mp3crickets-b50f1da0.mp3crown-00d190cb.svgcurb-f9327cfc.mp3dadgummit-6c84151f.mp3dangerzone-7382b27e.mp3danielsan-0815085a.mp3deeper-c9fe70a0.mp3default-avatar-1ee67b00.svgdefault-bot-avatar-de1d12f7.svgdisclosure-26d63471.svgdonotwant-fa71a459.mp3download-04029899.svgdrama-92fb52d2.mp3email-6c595bc5.svgembeds-c20d0a3a.csseveryone-4ca1d460.svgexternal/gear-50e77d2b.svgexternal/install-edge-0b7cd918.svgexternal/install-f762b3be.svgexternal/share-f9d3e998.svgexternal/sliders-3979a007.svgexternal/switch-eec22a2d.svgexternal/web-24ffe636.svgfilters-8a4d63ed.cssflash-a561c1e5.cssflawless-678d1f3c.mp3glados-f033ed9e.mp3globe-8c54d23b.svggogogo-f091ebbc.mp3greatjob-7d6aada2.mp3greyjoy-dcb0e786.mp3guarantee-8e639fbb.mp3help-circle-1bb1a839.svghelp-a18b47fc.svghelpers/dom_helpers-0f234176.jshelpers/navigator_helpers-3c9f4c31.jshelpers/string_helpers-40941ba8.jshelpers/timing_helpers-94d95529.jshelpers/turbo_helpers-a3c01462.jsheygirl-b9a85600.mp3highlight.js/core-4e141f64.jshonk-9c336a89.mp3horn-efb0f714.mp3horror-5181b7e4.mp3incoming-0621d199.mp3inconceivable-c8811768.mp3initializers/autocomplete-ba9abe45.jsinitializers/current-3a3b90da.jsinitializers/highlight-5bd558f1.jsinitializers/index-d2bbfae4.jsinitializers/rich_text-f451a05e.jsinputs-9e58a07c.cssinstall-edge-0b7cd918.svgkey-82330955.svglanguages/bash-13136668.jslanguages/css-a7f2e40b.jslanguages/diff-94a335fe.jslanguages/go-10465864.jslanguages/java-95f3a30f.jslanguages/javascript-18eb0dd8.jslanguages/json-60184e1b.jslanguages/python-8f48fd1a.jslanguages/ruby-287ccd0f.jslanguages/rust-d48f93d8.jslanguages/sql-642be05a.jslanguages/xml-fa7f1eda.jslanyard-945079e9.svglaptop-cf35e6d4.svglayout-ff6ddfc6.cssletitgo-bc89591d.mp3lexxy-content-0ff2f961.csslexxy-editor-2d5c7ebe.csslexxy-variables-3fef4323.csslexxy-2876c58e.csslexxy-a21f41d4.jslexxy.js-380cb9c9.brlexxy.js-9130cdde.gzlexxy-cf040c43.js.maplexxy.min-68f38983.jslexxy.min.js-02328003.brlexxy.min.js-56322c4c.gzlib/autocomplete/autocomplete_handler-becd1e1a.jslib/autocomplete/base_autocomplete_handler-96e7e419.jslib/autocomplete/collection-3e251a0e.jslib/autocomplete/constants-17c2858b.jslib/autocomplete/custom_elements/suggestion_option-ac7846b3.jslib/autocomplete/custom_elements/suggestion_select-f0045305.jslib/autocomplete/helpers-651308b9.jslib/autocomplete/renderer-5caf6120.jslib/autocomplete/selection-862705bf.jslib/autocomplete/suggestion_context-b265ffb4.jslib/autocomplete/suggestion_controller-10624c40.jslib/autocomplete/suggestion_results_controller-91405749.jslib/autocomplete/utils-296fb278.jslib/cookie-76006835.jslib/rich_text/campfire_extension-f62f017b.jslib/rich_text/cite_node-b4d2b89a.jslifebuoy-f31f26aa.svglightbox-af496d39.csslink-e546a5df.svglive-550f1f88.mp3lock-7cdf4b3d.svgloggins-63aac7af.mp3login-keys-df926967.svglogos/app-icon-192-646b105a.pnglogos/app-icon-a6fa894e.pnglogout-a6131db1.svgmakeitso-f6e530b1.mp3mario_coin-556717d1.mp3maybe-4a638e83.mp3menu-dots-horizontal-f6a5d793.svgmenu-dots-vertical-c247e3cc.svgmenu-5462dfd3.svgmessages-add-d229e6c2.svgmessages-empty-84c8fd41.svgmessages-outlined-87ff0331.svgmessages-c5485fef.cssmessages-9395d503.svgminus-b31a1093.svgmobile-phone-d0d2301d.svgmodels/client_message-de3c07cf.jsmodels/file_uploader-09a18428.jsmodels/message_formatter-f39a0c5d.jsmodels/message_paginator-b79013e3.jsmodels/scroll_manager-ed559629.jsmodels/typing_tracker-42a444a5.jsnav-05e7183a.cssnoooo-c68a85f4.mp3notification-bell-alert-b467cde7.svgnotification-bell-everything-cde41b14.svgnotification-bell-invisible-8b495073.svgnotification-bell-loading-7533ce55.svgnotification-bell-mentions-945d1b91.svgnotification-bell-nothing-d8096c76.svgnyan-1fe5c553.mp3office-69ba5668.svgohmy-189dd829.mp3ohyeah-48506f41.mp3panels-af44ec6d.csspassword-0896da4e.svgpencil-cf9d28aa.svgperson-add-1432b76b.svgperson-da193438.svgpushit-f43f90a7.mp3qr-code-dac3b273.svgrails-ujs.esm-e925103b.jsrails-ujs-20eaf715.jsrefresh-249f0509.svgremove-circle-384c618c.svgremove-0e7a045d.svgreply-edb77e33.svgrimshot-66c3332b.mp3rollout-3a826ae4.mp3rumble-7b5d6e4f.mp3sax-9e7841a8.mp3screenshots/android-chat-f8b923c9.pngscreenshots/android-dark-mode-e43dcf59.pngscreenshots/android-sidebar-e9d2b49f.pngsearch-5f29565f.svgsecret-9f61e3b5.mp3separators-172b3ab8.csssettings-aee56972.svgsexyback-ec0cf66f.mp3share-bf28da4f.svgsidebar-0be58db9.csssignup-6e02d591.csssounds/56k-22d60d09.gifsounds/56k-1567db5b.webpsounds/clowntown-fa123df7.gifsounds/clowntown-1670db9e.webpsounds/curb-0c6f596b.gifsounds/curb-b74cab9f.webpsounds/dangerzone-60067535.pngsounds/dangerzone-0e0f0d09.webpsounds/donotwant-c19843b2.gifsounds/donotwant-d29fb6fb.webpsounds/drama-b398c916.webpsounds/greatjob-d65f324c.pngsounds/greatjob-99af483c.webpsounds/loggins-a40a75e6.webpsounds/nyan-995f5ada.gifsounds/nyan-8cc577e4.webpsounds/pushit-599fd1e2.gifsounds/pushit-05915cda.webpsounds/rumble-5ddb8536.gifsounds/rumble-c4fc52a9.webpsounds/top-15f70a0c.gifsounds/top-cc086a68.webpsounds/what-5ff77085.gifsounds/what-02690db4.webpsounds/yay-6d9d9620.pngsounds/yay-914d17c4.webpsounds/yeah-7b10b5f7.gifsounds/yeah-886795b2.webpspinner-5a118f25.cssstimulus-autoloader-9d447422.jsstimulus-importmap-autoloader-64cc03e1.jsstimulus-loading-1fc53fe7.jsstimulus-d59b3b7f.jsstimulus.min-4b1e420e.jsstimulus.min-2395e199.js.mapstory-0665aaac.mp3tada-6500487f.mp3text-options-055e0d16.svgtmyk-035cbb8b.mp3totes-665011c8.mp3transfer-3ec4f61b.svgtrash-708c7eb2.svgtrix-65afdb1d.csstrix-4bf79781.jstrololo-d7f880d7.mp3trombone-3cbeabc3.mp3turbo-a1e3a50a.jsturbo.min-3a2e143f.jsturbo.min-5f3b7fda.js.mapunix-bb19b65d.mp3utilities-e2f32466.cssvuvuzela-d177cb0f.mp3web-e179f247.svgwhat-880c5f29.mp3whoomp-f21c3c43.mp3wups-fbad935c.mp3yay-1fae7a37.mp3yeah-71e3371e.mp3yodel-b14597bb.mp3";
    let starts = [0, 16, 43, 62, 86, 113, 136, 159, 185, 207, 236, 261, 277, 295, 317, 340, 363, 386, 410, 431, 447, 470, 495, 515, 535, 552, 569, 587, 603, 621, 640, 656, 674, 703, 731, 757, 786, 813, 841, 861, 881, 899, 918, 944, 963, 981, 1003, 1020, 1041, 1060, 1089, 1110, 1145, 1191, 1238, 1282, 1329, 1372, 1424, 1470, 1520, 1561, 1600, 1629, 1672, 1717, 1767, 1810, 1858, 1898, 1941, 1987, 2032, 2079, 2119, 2164, 2215, 2264, 2307, 2355, 2401, 2441, 2488, 2534, 2584, 2639, 2680, 2729, 2773, 2796, 2821, 2842, 2860, 2877, 2899, 2922, 2944, 2963, 2990, 3021, 3044, 3066, 3087, 3105, 3123, 3142, 3163, 3189, 3223, 3252, 3279, 3308, 3336, 3361, 3381, 3399, 3420, 3439, 3457, 3476, 3497, 3517, 3539, 3563, 3580, 3611, 3648, 3682, 3716, 3749, 3769, 3798, 3815, 3832, 3851, 3872, 3898, 3935, 3967, 4001, 4031, 4065, 4084, 4109, 4125, 4151, 4176, 4202, 4226, 4252, 4284, 4310, 4338, 4364, 4390, 4415, 4440, 4460, 4479, 4498, 4518, 4544, 4569, 4597, 4615, 4632, 4652, 4672, 4693, 4714, 4738, 4762, 4811, 4865, 4904, 4942, 5004, 5066, 5102, 5139, 5177, 5224, 5274, 5332, 5366, 5388, 5432, 5467, 5488, 5509, 5526, 5543, 5560, 5580, 5603, 5634, 5661, 5680, 5701, 5724, 5742, 5775, 5806, 5823, 5848, 5875, 5905, 5926, 5947, 5965, 5990, 6023, 6055, 6091, 6127, 6160, 6193, 6209, 6227, 6263, 6304, 6344, 6382, 6421, 6459, 6476, 6495, 6512, 6531, 6550, 6571, 6590, 6613, 6632, 6651, 6671, 6696, 6717, 6737, 6763, 6782, 6800, 6820, 6840, 6859, 6875, 6912, 6954, 6994, 7013, 7032, 7055, 7076, 7097, 7115, 7135, 7154, 7177, 7201, 7230, 7260, 7284, 7309, 7339, 7370, 7399, 7429, 7455, 7483, 7512, 7540, 7564, 7589, 7615, 7642, 7668, 7695, 7718, 7742, 7766, 7791, 7814, 7838, 7862, 7887, 7907, 7938, 7979, 8007, 8027, 8051, 8079, 8097, 8114, 8139, 8156, 8174, 8195, 8213, 8230, 8246, 8266, 8287, 8304, 8325, 8350, 8367, 8389, 8410, 8426, 8443, 8462, 8479, 8495, 8512];
    let sizes = [16, 27, 19, 24, 27, 23, 23, 26, 22, 29, 25, 16, 18, 22, 23, 23, 23, 24, 21, 16, 23, 25, 20, 20, 17, 17, 18, 16, 18, 19, 16, 18, 29, 28, 26, 29, 27, 28, 20, 20, 18, 19, 26, 19, 18, 22, 17, 21, 19, 29, 21, 35, 46, 47, 44, 47, 43, 52, 46, 50, 41, 39, 29, 43, 45, 50, 43, 48, 40, 43, 46, 45, 47, 40, 45, 51, 49, 43, 48, 46, 40, 47, 46, 50, 55, 41, 49, 44, 23, 25, 21, 18, 17, 22, 23, 22, 19, 27, 31, 23, 22, 21, 18, 18, 19, 21, 26, 34, 29, 27, 29, 28, 25, 20, 18, 21, 19, 18, 19, 21, 20, 22, 24, 17, 31, 37, 34, 34, 33, 20, 29, 17, 17, 19, 21, 26, 37, 32, 34, 30, 34, 19, 25, 16, 26, 25, 26, 24, 26, 32, 26, 28, 26, 26, 25, 25, 20, 19, 19, 20, 26, 25, 28, 18, 17, 20, 20, 21, 21, 24, 24, 49, 54, 39, 38, 62, 62, 36, 37, 38, 47, 50, 58, 34, 22, 44, 35, 21, 21, 17, 17, 17, 20, 23, 31, 27, 19, 21, 23, 18, 33, 31, 17, 25, 27, 30, 21, 21, 18, 25, 33, 32, 36, 36, 33, 33, 16, 18, 36, 41, 40, 38, 39, 38, 17, 19, 17, 19, 19, 21, 19, 23, 19, 19, 20, 25, 21, 20, 26, 19, 18, 20, 20, 19, 16, 37, 42, 40, 19, 19, 23, 21, 21, 18, 20, 19, 23, 24, 29, 30, 24, 25, 30, 31, 29, 30, 26, 28, 29, 28, 24, 25, 26, 27, 26, 27, 23, 24, 24, 25, 23, 24, 24, 25, 20, 31, 41, 28, 20, 24, 28, 18, 17, 25, 17, 18, 21, 18, 17, 16, 20, 21, 17, 21, 25, 17, 22, 21, 16, 17, 19, 17, 16, 17, 18];
    guard index >= 0 && index < starts.len else { return ""; }
    return data[starts[index]..starts[index]+sizes[index]];
}

fn asset_mime(index: i64) -> const u8[:] {
    let data = "audio/mpegtext/javascripttext/csstext/javascripttext/javascripttext/javascripttext/csstext/javascripttext/javascripttext/javascripttext/javascriptimage/svg+xmlimage/svg+xmltext/csstext/javascriptimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmltext/csstext/cssaudio/mpegtext/cssaudio/mpegaudio/mpegimage/svg+xmlimage/svg+xmltext/cssimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlaudio/mpegtext/cssaudio/mpegimage/svg+xmlimage/pngimage/svg+xmlimage/svg+xmlaudio/mpegtext/csstext/csstext/cssimage/svg+xmltext/csstext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascriptimage/svg+xmlaudio/mpegaudio/mpegimage/svg+xmlaudio/mpegaudio/mpegaudio/mpegaudio/mpegaudio/mpegimage/svg+xmlimage/svg+xmlimage/svg+xmlaudio/mpegimage/svg+xmlaudio/mpegimage/svg+xmltext/cssimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmltext/csstext/cssaudio/mpegaudio/mpegimage/svg+xmlaudio/mpegaudio/mpegaudio/mpegaudio/mpegimage/svg+xmlimage/svg+xmltext/javascripttext/javascripttext/javascripttext/javascripttext/javascriptaudio/mpegtext/javascriptaudio/mpegaudio/mpegaudio/mpegaudio/mpegaudio/mpegtext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/cssimage/svg+xmlimage/svg+xmltext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascriptimage/svg+xmlimage/svg+xmltext/cssaudio/mpegtext/csstext/csstext/csstext/csstext/javascripttext/plainapplication/x-gziptext/plaintext/javascripttext/plainapplication/x-gziptext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascriptimage/svg+xmltext/cssimage/svg+xmlaudio/mpegimage/svg+xmlaudio/mpegimage/svg+xmlimage/pngimage/pngimage/svg+xmlaudio/mpegaudio/mpegaudio/mpegimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmltext/cssimage/svg+xmlimage/svg+xmlimage/svg+xmltext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/cssaudio/mpegimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlaudio/mpegimage/svg+xmlaudio/mpegaudio/mpegtext/cssimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlaudio/mpegimage/svg+xmltext/javascripttext/javascriptimage/svg+xmlimage/svg+xmlimage/svg+xmlimage/svg+xmlaudio/mpegaudio/mpegaudio/mpegaudio/mpegimage/pngimage/pngimage/pngimage/svg+xmlaudio/mpegtext/cssimage/svg+xmlaudio/mpegimage/svg+xmltext/csstext/cssimage/gifimage/webpimage/gifimage/webpimage/gifimage/webpimage/pngimage/webpimage/gifimage/webpimage/webpimage/pngimage/webpimage/webpimage/gifimage/webpimage/gifimage/webpimage/gifimage/webpimage/gifimage/webpimage/gifimage/webpimage/pngimage/webpimage/gifimage/webptext/csstext/javascripttext/javascripttext/javascripttext/javascripttext/javascripttext/plainaudio/mpegaudio/mpegimage/svg+xmlaudio/mpegaudio/mpegimage/svg+xmlimage/svg+xmltext/csstext/javascriptaudio/mpegaudio/mpegtext/javascripttext/javascripttext/plainaudio/mpegtext/cssaudio/mpegimage/svg+xmlaudio/mpegaudio/mpegaudio/mpegaudio/mpegaudio/mpegaudio/mpeg";
    let starts = [0, 10, 25, 33, 48, 63, 78, 86, 101, 116, 131, 146, 159, 172, 180, 195, 208, 221, 234, 247, 260, 273, 281, 289, 299, 307, 317, 327, 340, 353, 361, 374, 387, 400, 413, 426, 439, 452, 465, 475, 483, 493, 506, 515, 528, 541, 551, 559, 567, 575, 588, 596, 611, 626, 641, 656, 671, 686, 701, 716, 731, 746, 761, 776, 791, 806, 821, 836, 851, 866, 881, 896, 911, 926, 941, 956, 971, 986, 1001, 1016, 1031, 1046, 1061, 1076, 1091, 1106, 1121, 1136, 1151, 1164, 1174, 1184, 1197, 1207, 1217, 1227, 1237, 1247, 1260, 1273, 1286, 1296, 1309, 1319, 1332, 1340, 1353, 1366, 1379, 1392, 1405, 1418, 1431, 1444, 1452, 1460, 1470, 1480, 1493, 1503, 1513, 1523, 1533, 1546, 1559, 1574, 1589, 1604, 1619, 1634, 1644, 1659, 1669, 1679, 1689, 1699, 1709, 1724, 1739, 1754, 1769, 1784, 1792, 1805, 1818, 1833, 1848, 1863, 1878, 1893, 1908, 1923, 1938, 1953, 1968, 1983, 1998, 2011, 2024, 2032, 2042, 2050, 2058, 2066, 2074, 2089, 2099, 2117, 2127, 2142, 2152, 2170, 2185, 2200, 2215, 2230, 2245, 2260, 2275, 2290, 2305, 2320, 2335, 2350, 2365, 2380, 2395, 2410, 2423, 2431, 2444, 2454, 2467, 2477, 2490, 2499, 2508, 2521, 2531, 2541, 2551, 2564, 2577, 2590, 2603, 2616, 2629, 2637, 2650, 2663, 2676, 2691, 2706, 2721, 2736, 2751, 2766, 2774, 2784, 2797, 2810, 2823, 2836, 2849, 2862, 2872, 2885, 2895, 2905, 2913, 2926, 2939, 2952, 2965, 2975, 2988, 3003, 3018, 3031, 3044, 3057, 3070, 3080, 3090, 3100, 3110, 3119, 3128, 3137, 3150, 3160, 3168, 3181, 3191, 3204, 3212, 3220, 3229, 3239, 3248, 3258, 3267, 3277, 3286, 3296, 3305, 3315, 3325, 3334, 3344, 3354, 3363, 3373, 3382, 3392, 3401, 3411, 3420, 3430, 3439, 3449, 3458, 3468, 3477, 3487, 3495, 3510, 3525, 3540, 3555, 3570, 3580, 3590, 3600, 3613, 3623, 3633, 3646, 3659, 3667, 3682, 3692, 3702, 3717, 3732, 3742, 3752, 3760, 3770, 3783, 3793, 3803, 3813, 3823, 3833];
    let sizes = [10, 15, 8, 15, 15, 15, 8, 15, 15, 15, 15, 13, 13, 8, 15, 13, 13, 13, 13, 13, 13, 8, 8, 10, 8, 10, 10, 13, 13, 8, 13, 13, 13, 13, 13, 13, 13, 13, 10, 8, 10, 13, 9, 13, 13, 10, 8, 8, 8, 13, 8, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 13, 10, 10, 13, 10, 10, 10, 10, 10, 13, 13, 13, 10, 13, 10, 13, 8, 13, 13, 13, 13, 13, 13, 13, 13, 8, 8, 10, 10, 13, 10, 10, 10, 10, 13, 13, 15, 15, 15, 15, 15, 10, 15, 10, 10, 10, 10, 10, 15, 15, 15, 15, 15, 8, 13, 13, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 13, 13, 8, 10, 8, 8, 8, 8, 15, 10, 18, 10, 15, 10, 18, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 13, 8, 13, 10, 13, 10, 13, 9, 9, 13, 10, 10, 10, 13, 13, 13, 13, 13, 13, 8, 13, 13, 13, 15, 15, 15, 15, 15, 15, 8, 10, 13, 13, 13, 13, 13, 13, 10, 13, 10, 10, 8, 13, 13, 13, 13, 10, 13, 15, 15, 13, 13, 13, 13, 10, 10, 10, 10, 9, 9, 9, 13, 10, 8, 13, 10, 13, 8, 8, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 10, 9, 10, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 8, 15, 15, 15, 15, 15, 10, 10, 10, 13, 10, 10, 13, 13, 8, 15, 10, 10, 15, 15, 10, 10, 8, 10, 13, 10, 10, 10, 10, 10, 10];
    guard index >= 0 && index < starts.len else { return ""; }
    return data[starts[index]..starts[index]+sizes[index]];
}

fn asset_path(source: const u8[:]) -> u8[>..] {
    if starts_with(source, "/") || find(source, ":") >= 0 { return str(source); }
    let index = asset_logical_index(source);
    guard index >= 0 else { abort(str("Missing asset: ", source)); }
    return str("/assets/", asset_filename(index));
}
