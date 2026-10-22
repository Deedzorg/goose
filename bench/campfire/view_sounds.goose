// Built-in sound definitions from the pinned reference; see views/source.json.
namespace campfire;
import std;
import html;
import view_assets_generated;
fn sound_content(name: const u8[:]) -> u8[>..] {
    var out: u8[>..]=[];
    if name=="56k" {
        format(out,"<img width=\"79\" height=\"33\" class=\"align--middle\" src=\"",asset_path("sounds/56k.webp"),"\" />");
        return out;
    }
    if name=="bell" {
        escape(out,"🔔");
        return out;
    }
    if name=="bezos" {
        escape(out,"😆💭");
        return out;
    }
    if name=="bueller" {
        escape(out,"anyone?");
        return out;
    }
    if name=="butts" {
        escape(out,"👐 🚬");
        return out;
    }
    if name=="clowntown" {
        format(out,"<img width=\"210\" height=\"150\" class=\"align--middle\" src=\"",asset_path("sounds/clowntown.webp"),"\" />");
        return out;
    }
    if name=="cottoneyejoe" {
        escape(out,"🎶🙉🎶 ");
        return out;
    }
    if name=="crickets" {
        escape(out,"hears crickets chirping");
        return out;
    }
    if name=="curb" {
        format(out,"<img width=\"150\" height=\"101\" class=\"align--middle\" src=\"",asset_path("sounds/curb.webp"),"\" />");
        return out;
    }
    if name=="dadgummit" {
        escape(out,"dad gummit!! 🎣");
        return out;
    }
    if name=="dangerzone" {
        format(out,"<img width=\"157\" height=\"32\" class=\"align--middle\" src=\"",asset_path("sounds/dangerzone.webp"),"\" />");
        return out;
    }
    if name=="danielsan" {
        escape(out,"🎆 🏆 🎆");
        return out;
    }
    if name=="deeper" {
        format(out,"<img width=\"188\" height=\"80\" class=\"align--middle\" src=\"",asset_path("sounds/top.webp"),"\" />");
        return out;
    }
    if name=="ballmer" {
        escape(out,"developers!");
        return out;
    }
    if name=="donotwant" {
        format(out,"<img width=\"150\" height=\"150\" class=\"align--middle\" src=\"",asset_path("sounds/donotwant.webp"),"\" />");
        return out;
    }
    if name=="drama" {
        format(out,"<img width=\"300\" height=\"16\" class=\"align--middle\" src=\"",asset_path("sounds/drama.webp"),"\" />");
        return out;
    }
    if name=="flawless" {
        escape(out,"#flawless");
        return out;
    }
    if name=="glados" {
        escape(out,"🤖💢");
        return out;
    }
    if name=="gogogo" {
        escape(out,"Go, go, go!");
        return out;
    }
    if name=="greatjob" {
        format(out,"<img width=\"79\" height=\"16\" class=\"align--middle\" src=\"",asset_path("sounds/greatjob.webp"),"\" />");
        return out;
    }
    if name=="greyjoy" {
        escape(out,"😖🎺");
        return out;
    }
    if name=="guarantee" {
        escape(out,"guarantees it 👌");
        return out;
    }
    if name=="heygirl" {
        escape(out,"✨💁✨");
        return out;
    }
    if name=="honk" {
        escape(out,"HONK");
        return out;
    }
    if name=="horn" {
        escape(out,"🐶 ✂️ 🐱");
        return out;
    }
    if name=="horror" {
        escape(out,"💀 💀 💀 💀 💀 💀 💀");
        return out;
    }
    if name=="inconceivable" {
        escape(out,"doesn't think it means what you think it means…");
        return out;
    }
    if name=="letitgo" {
        escape(out,"❄️👩❄️⛄️❄️");
        return out;
    }
    if name=="live" {
        escape(out,"is DOING IT LIVE");
        return out;
    }
    if name=="loggins" {
        format(out,"<img width=\"200\" height=\"151\" class=\"align--middle\" src=\"",asset_path("sounds/loggins.webp"),"\" />");
        return out;
    }
    if name=="makeitso" {
        escape(out,"make it so 👉");
        return out;
    }
    if name=="noooo" {
        escape(out,"👸💀😒");
        return out;
    }
    if name=="nyan" {
        format(out,"<img width=\"36\" height=\"15\" class=\"align--middle\" src=\"",asset_path("sounds/nyan.webp"),"\" />");
        return out;
    }
    if name=="ohmy" {
        escape(out,"raises an eyebrow 😏");
        return out;
    }
    if name=="ohyeah" {
        escape(out,"isn't playing by the rules");
        return out;
    }
    if name=="pushit" {
        format(out,"<img width=\"104\" height=\"15\" class=\"align--middle\" src=\"",asset_path("sounds/pushit.webp"),"\" />");
        return out;
    }
    if name=="rimshot" {
        escape(out,"plays a rimshot");
        return out;
    }
    if name=="rollout" {
        escape(out,"is rolling out 🚗");
        return out;
    }
    if name=="rumble" {
        format(out,"<img width=\"220\" height=\"150\" class=\"align--middle\" src=\"",asset_path("sounds/rumble.webp"),"\" />");
        return out;
    }
    if name=="sax" {
        escape(out,"🌇🎷🎶");
        return out;
    }
    if name=="secret" {
        escape(out,"found a secret area 🔑");
        return out;
    }
    if name=="sexyback" {
        escape(out,"🔞");
        return out;
    }
    if name=="story" {
        escape(out,"and now you know…");
        return out;
    }
    if name=="tada" {
        escape(out,"plays a fanfare 🎏");
        return out;
    }
    if name=="tmyk" {
        escape(out,"✨ ⭐️ The More You Know ✨ ⭐️");
        return out;
    }
    if name=="totes" {
        escape(out,"😁👍");
        return out;
    }
    if name=="trololo" {
        escape(out,"трололо");
        return out;
    }
    if name=="trombone" {
        escape(out,"plays a sad trombone");
        return out;
    }
    if name=="unix" {
        escape(out,"knows this 💻");
        return out;
    }
    if name=="vuvuzela" {
        escape(out,"======<() ~ ♪ ~♫");
        return out;
    }
    if name=="what" {
        format(out,"<img width=\"100\" height=\"131\" class=\"align--middle\" src=\"",asset_path("sounds/what.webp"),"\" />");
        return out;
    }
    if name=="whoomp" {
        escape(out,"👏‼️😎");
        return out;
    }
    if name=="wups" {
        escape(out,"wups!");
        return out;
    }
    if name=="yay" {
        format(out,"<img width=\"103\" height=\"50\" class=\"align--middle\" src=\"",asset_path("sounds/yay.webp"),"\" />");
        return out;
    }
    if name=="yeah" {
        format(out,"<img width=\"104\" height=\"15\" class=\"align--middle\" src=\"",asset_path("sounds/yeah.webp"),"\" />");
        return out;
    }
    if name=="yodel" {
        escape(out,"📣🗻🙉");
        return out;
    }
    return out;
}
