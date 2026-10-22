namespace campfire;
import std;

struct UserView {
    id: i64 = 0,
    name: const u8[:] = "",
    title: const u8[:] = "",
    first_name: const u8[:] = "",
    avatar_url: const u8[:] = "",
    path: const u8[:] = "",
    administrator: bool = false,
}

struct AttachmentView {
    filename: const u8[:] = "",
    blob_path: const u8[:] = "",
    download_path: const u8[:] = "",
}

struct BoostView {
    id: i64 = 0,
    dom_id: const u8[:] = "",
    path: const u8[:] = "",
    content: const u8[:] = "",
    all_emoji: bool = false,
    booster: UserView = UserView { .. },
}

struct MessageView {
    id: i64 = 0,
    room_id: i64 = 0,
    room_name: const u8[:] = "",
    dom_id: const u8[:] = "",
    at_path: const u8[:] = "",
    edit_path: const u8[:] = "",
    boosts_path: const u8[:] = "",
    new_boost_path: const u8[:] = "",
    creator: UserView = UserView { .. },
    created_ms: i64 = 0,
    updated_ms: i64 = 0,
    created_iso: const u8[:] = "",
    presentation: const u8[:] = "",
    unrenderable: bool = false,
    all_emoji: bool = false,
    has_attachment: bool = false,
    attachment: AttachmentView = AttachmentView { .. },
    boosts: const BoostView[:] = EMPTY_BOOSTS,
}

struct RoomView {
    id: i64 = 0,
    kind: const u8[:] = "",
    param_key: const u8[:] = "",
    name: const u8[:] = "",
    display_name: const u8[:] = "",
    dom_id: const u8[:] = "",
    edit_path: const u8[:] = "",
    direct: bool = false,
    noun: const u8[:] = "",
    classes: const u8[:] = "",
    updated_ms: i64 = 0,
}

struct DirectView {
    room_id: i64 = 0,
    updated_at_epoch: const u8[:] = "",
    classes: const u8[:] = "",
    initials: const u8[:] = "",
    members: const UserView[:] = EMPTY_USERS,
}

struct PlatformView {
    browser: const u8[:] = "",
    operating_system: const u8[:] = "",
    android: bool = false, ios: bool = false, desktop: bool = false,
    windows: bool = false, chrome: bool = false, safari: bool = false,
    firefox: bool = false, edge: bool = false,
}

struct AccountView {
    name: const u8[:] = "",
    has_logo: bool = false,
    logo_url: const u8[:] = "",
}

struct ViewContext {
    storage_key: const u8[:] = "",
    user: UserView = UserView { .. },
    room: RoomView = RoomView { .. },
    account: AccountView = AccountView { .. },
    platform: PlatformView = PlatformView { .. },
    title: const u8[:] = "",
    body_class: const u8[:] = "",
    base_url: const u8[:] = "",
    vapid_public_key: const u8[:] = "",
    stylesheet_tags: const u8[:] = "",
    importmap_tags: const u8[:] = "",
    custom_styles: const u8[:] = "",
    has_custom_styles: bool = false,
    notice: const u8[:] = "",
    has_alert: bool = false,
    messages: const MessageView[:] = EMPTY_MESSAGES,
    invitation: bool = false,
    join_code: const u8[:] = "",
    messages_stream_name: const u8[:] = "",
    rooms_stream: const u8[:] = "",
    user_rooms_stream: const u8[:] = "",
    can_create_rooms: bool = false,
    other_memberships: const RoomView[:] = EMPTY_ROOMS,
    direct_memberships: const DirectView[:] = EMPTY_DIRECTS,
    placeholders: const UserView[:] = EMPTY_USERS,
    recent_searches: const (const u8[:])[:] = EMPTY_SEARCHES,
    has_query: bool = false,
    query: const u8[:] = "",
    q: const u8[:] = "",
    return_to_room_id: i64 = 0,
}

const EMPTY_BOOSTS: BoostView[0] = [];
const EMPTY_USERS: UserView[0] = [];
const EMPTY_MESSAGES: MessageView[0] = [];
const EMPTY_ROOMS: RoomView[0] = [];
const EMPTY_DIRECTS: DirectView[0] = [];
const EMPTY_SEARCHES: const u8[:][0] = [];
