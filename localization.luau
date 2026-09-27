-- Taiwan TV terminology and project-authored translations; sources in docs/localization-zh-TW.md.
local L = {}
export type Locale = 'en' | 'zh-TW'
L.languageLabel = '繁中（台灣）'
L.catalog = {
    ['TEEN TITANS'] = '少年悍將',
    ['JUMP CITY BRAWL'] = '雀躍城大亂鬥',
    ['ROBIN'] = '羅賓', ['CYBORG'] = '鋼骨', ['STARFIRE'] = '俏嬌娃',
    ['RAVEN'] = '酷姬', ['BEAST BOY'] = '人皮獸',
    ['SLADE BOT'] = '史萊德機器兵', ['HEAVY BOT'] = '重裝機器兵',
    ['RAZOR BOT'] = '利刃機器兵', ['BLASTER BOT'] = '砲擊機器兵',
    ['GUARD BOT'] = '盾牌機器兵', ['SHOCK BOT'] = '電擊機器兵',
    ['CINDERBLOCK'] = '石頭怪', ['MAMMOTH'] = '瑪莫', ['JINX'] = '金兒', ['SLADE'] = '史萊德',
    ['BIRDARANG'] = '鳥飛鏢', ['SONIC CANNON'] = '音波砲',
    ['STARBOLT VOLLEY'] = '星光連發', ['DARK BURST'] = '暗影爆發', ['RHINO CHARGE'] = '犀牛衝撞',
    ['STAFF CYCLONE'] = '旋風棍', ['SEISMIC SLAM'] = '震地重擊', ['COMET RUSH'] = '彗星突擊',
    ['SHADOW GRASP'] = '暗影束縛', ['GORILLA SMASH'] = '猩猩重擊',
    ['BIRDARANG STORM'] = '鳥飛鏢風暴', ['MEGA SONIC CANNON'] = '超級音波砲',
    ['STAR NOVA'] = '超新星爆發', ['SOUL SELF'] = '靈魂投射', ['T-REX RAMPAGE'] = '暴龍大暴走',
    ['BIRDARANG!'] = '鳥飛鏢！', ['BOOYAH!'] = 'BOOYAH!', ['STARBOLTS!'] = '星光彈！',
    ['AZARATH METRION ZINTHOS!'] = '天地萬物聽我命令！', ['RHINO TIME, DUDE!'] = '犀牛出動啦！',
    ['POW!'] = '砰！', ['BAM!'] = '碰！', ['WHAM!'] = '咚！', ['KAPOW!'] = '轟！',
    ['THWACK!'] = '啪！', ['BOOM!'] = '轟隆！', ['BLOCK'] = '格擋', ['PIZZA!'] = '披薩！',
    ['JUMP CITY'] = '雀躍城', ['STREET SWEEP'] = '街頭掃蕩',
    ['IRON DOCKS'] = '鋼鐵碼頭', ['BREAK THE BLOCKADE'] = '突破封鎖',
    ['HEX FOUNDRY'] = '咒術工廠', ['SHUT DOWN THE MACHINES'] = '摧毀機器',
    ['SLADE HQ'] = '史萊德總部', ['ROOFTOP SHOWDOWN'] = '屋頂決戰',
    ['TITANS, GO!'] = '少年悍將，出動！',
    ['JUMP OVER THE SHOCKWAVE'] = '跳起來閃過震波', ['SIDESTEP HIS CHARGE'] = '上下移動閃避衝撞',
    ['DODGE THE HEX VOLLEY'] = '閃避咒術連發', ['THE FINAL SHOWDOWN'] = '最終決戰',
    ['STAGE {stage} / HEALTH AND ENERGY RESTORED'] = '第 {stage} 關／生命與能量已恢復',
    ['JUMP!'] = '快跳！', ['RUSH!'] = '衝撞！', ['GO!'] = '前進！',
    ['P{player} PRESS START'] = 'P{player} 按 START 加入',
    ['CONTINUE? START'] = '按 START 繼續',
    ['{stage}/4  {name}  -  WAVE {wave}/4'] = '{stage}/4  {name}  第 {wave}/4 波',
    ['{players}P  ENEMIES {count}'] = '{players} 人遊玩  剩餘敵人 {count}',
    ['PRESS START'] = '按 START 開始',
    ['X: ATTACK   A: JUMP   B: SPECIAL   Y: SECONDARY   RT: ULTIMATE   START: JOIN / PAUSE'] = 'X：攻擊   A：跳躍   B：特殊技   Y：第二招式   RT：必殺技   START：加入／暫停',
    ['1-4 PLAYERS   CONTROLLERS CONNECTED: {count}'] = '1–4 人遊玩　已連接控制器：{count}',
    ['UNOFFICIAL FAN GAME'] = '非官方同人遊戲',
    ['TAB / LB: LANGUAGE'] = 'TAB／LB：切換語言',
    ['CHOOSE YOUR TITAN'] = '選擇你的悍將', ['PLAYER {player}'] = '玩家 {player}',
    ['TO JOIN'] = '加入遊戲', ['KEYBOARD 1'] = '鍵盤 1', ['KEYBOARD 2'] = '鍵盤 2',
    ['CONTROLLER {id}'] = '控制器 {id}',
    ['POWER'] = '威力', ['SPEED'] = '速度', ['HEALTH'] = '生命',
    ['READY!'] = '準備好了！', ['STARTING IN {seconds}'] = '{seconds} 秒後出發',
    ['MOVE: PICK   A: READY   B: BACK   START: JOIN'] = '方向：選擇   A：準備   B：返回   START：加入',
    ['JUMP CITY IS SAFE!'] = '雀躍城安全了！', ['TITANS WIN!'] = '悍將們獲勝！',
    ['GAME OVER'] = '遊戲結束', ['CONTINUE?'] = '要繼續嗎？', ['PAUSED'] = '暫停中',
    ['START: RESUME    BACK / ESC: QUIT TO TITLE'] = 'START：繼續    BACK／ESC：回主選單',
    ['HIVE CARGO'] = '海夫貨運', ['H.I.V.E. HEX REACTOR'] = '海夫咒術反應爐',
    ['SLADE INDUSTRIES'] = '史萊德工業', ['PIZZA'] = '披薩', ['ARCADE'] = '遊樂場',
    ['COMICS'] = '漫畫', ['TACOS'] = '墨西哥捲餅', ['MUSIC'] = '音樂',
    ['TOWER GYM'] = '高塔健身房', ['DONUTS'] = '甜甜圈',
} :: { [string]: string }

-- Banter is authored as paired translations so variants cannot drift apart.
for _, character in require('remarks_catalog') do
    for _, lines in character do
        for _, line in lines do L.catalog[line[1]] = line[2] end
    end
end

function L.text(locale: Locale, source: string): string
    return if locale == 'zh-TW' then L.catalog[source] or source else source
end

-- Named placeholders keep word order in the translation, never in gameplay code.
function L.format(locale: Locale, source: string, values: { [string]: string | number }): string
    local result = string.gsub(L.text(locale, source), '{([%w_]+)}', function(key: string): string
        local value = values[key]
        assert(value ~= nil, `Missing localization value: {key}`)
        return tostring(value)
    end)
    return result
end

function L.toggle(locale: Locale): Locale
    return if locale == 'en' then 'zh-TW' else 'en'
end

return L
