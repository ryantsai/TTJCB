-- Taiwan TV terminology and project-authored translations; sources in docs/localization-zh-TW.md.
local L = {}
export type Locale = 'en' | 'zh-TW'
L.languageLabel = '繁中（台灣）'
L.catalog = {
    ['MOD ROBOT'] = '魔摩機器兵',
    ['HIVE CADET'] = '蜂巢學員',
    ['GORDANIAN'] = '戈爾達戰士',
    ['FIRE DEMON'] = '火焰惡魔',
    ['MAD MOD'] = '魔摩',
    ['BROTHER BLOOD'] = '血腥兄弟',
    ['BLACKFIRE'] = '黑火',
    ['TRIGON'] = '三宮魔',
    ['MAD MOD SCHOOL'] = '魔摩學校',
    ['ESCAPE THE ILLUSION'] = '逃離幻境',
    ['HIVE ACADEMY'] = '蜂巢學院',
    ['BREAK BLOODS CONTROL'] = '打破精神控制',
    ['TAMARAN'] = '塔瑪蘭星',
    ['CHALLENGE THE THRONE'] = '挑戰王座',
    ['TRIGONS EARTH'] = '三宮魔的地球',
    ['THE END'] = '末日決戰',
    ['{stage}/8  {name}  -  WAVE {wave}/4'] = '{stage}/8  {name}  第 {wave}/4 波',
    ['{count} / 8 LEVELS CLEARED'] = '已完成 {count} / 8 關',
    ['Defeat Trigon and restore the world.'] = '擊敗三宮魔，讓世界恢復原貌。',
    ['JUMP THE STEAM'] = '跳過蒸氣',
    ['CARGO TRUCK - CLEAR THE LANE'] = '貨車來襲，離開車道',
    ['REACTOR VENT - MOVE AWAY'] = '反應爐噴發，快離開',
    ['SECURITY LASER - JUMP'] = '雷射警戒，跳起來',
    ['FALSE FLOOR - JUMP OR MOVE'] = '陷阱地板，跳躍或移動',
    ['SONIC FIELD - JUMP'] = '音波力場，跳起來',
    ['ORBITAL STRIKE - MOVE AWAY'] = '軌道砲擊，快離開',
    ['HELLFIRE - MOVE AWAY'] = '地獄火，快離開',
    ['JUMP THE SLAM - DODGE THE FIRE'] = '跳過震波，閃開火焰',
    ['BOSS BATTLE'] = '頭目戰',
    ['TRIGON SLAM - JUMP!'] = '三宮魔重擊，跳起來！',
    ['HELLFIRE VOLLEY - CHANGE LANES'] = '地獄火連發，換條路線',

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
    ['PRESS SPACE / START'] = '按 SPACE／START 開始',
    ['X: ATTACK   A: JUMP   B: SPECIAL   Y: SECONDARY   RT: ULTIMATE   START: JOIN / PAUSE'] = 'X：攻擊   A：跳躍   B：特殊技   Y：第二招式   RT：必殺技   START：加入／暫停',
    ['1-4 PLAYERS   CONTROLLERS CONNECTED: {count}'] = '1–4 人遊玩　已連接控制器：{count}',
    ['TEEN TITANS AND RELATED CHARACTERS BELONG TO THEIR RESPECTIVE RIGHTS HOLDERS.'] = '《少年悍將》及相關角色的權利均屬於各自的權利人。',
    ['THIS PROJECT IS NOT AFFILIATED WITH, ENDORSED BY, OR SPONSORED BY THEM.'] = '本作品與上述權利人無關，亦未獲其認可或贊助。',
    ['UNOFFICIAL FAN GAME'] = '非官方同人遊戲',
    ['TAB / LB: LANGUAGE'] = 'TAB／LB：切換語言',
    ['CHOOSE YOUR TITAN'] = '選擇你的悍將', ['PLAYER {player}'] = '玩家 {player}',
    ['TO JOIN'] = '加入遊戲', ['KEYBOARD 1'] = '鍵盤 1', ['KEYBOARD 2'] = '鍵盤 2',
    ['CONTROLLER {id}'] = '控制器 {id}',
    ['POWER'] = '威力', ['SPEED'] = '速度', ['HEALTH'] = '生命',
    ['Skill 1'] = '招式1', ['Skill 2'] = '招式2', ['Super'] = '絕招',
    ['READY!'] = '準備好了！', ['STARTING IN {seconds}'] = '{seconds} 秒後出發',
    ['MOVE: PICK   A: READY   B: BACK   START: JOIN'] = '方向：選擇   A：準備   B：返回   START：加入',
    ['JUMP CITY IS SAFE!'] = '雀躍城安全了！', ['TITANS WIN!'] = '悍將們獲勝！',
    ['GAME OVER'] = '遊戲結束', ['CONTINUE?'] = '要繼續嗎？', ['PAUSED'] = '暫停中',
    ['START: RESUME    BACK / ESC: QUIT TO TITLE'] = 'START：繼續    BACK／ESC：回主選單',
    ['HIVE CARGO'] = '海夫貨運', ['H.I.V.E. HEX REACTOR'] = '海夫咒術反應爐',
    ['SLADE INDUSTRIES'] = '史萊德工業', ['PIZZA'] = '披薩', ['ARCADE'] = '遊樂場',
    ['COMICS'] = '漫畫', ['TACOS'] = '墨西哥捲餅', ['MUSIC'] = '音樂',
    ['TOWER GYM'] = '高塔健身房', ['DONUTS'] = '甜甜圈',
    ['HOW TO PLAY'] = '操作教學', ["ROBIN'S CRASH COURSE"] = '羅賓的操作教學',
    ['SKIP'] = '略過', ['NEXT >'] = '下一步 >', ['DONE'] = '完成',
    ['CONTROLLER'] = '控制器', ['AUTO DEMO'] = '自動示範', ['BACK TO MENU'] = '回主選單',
    ['HIGHLIGHTED BUTTONS PLAY THE DEMO'] = '亮起的按鍵會同步操控羅賓',
    ['WATCH ROBIN. SKIP ANYTIME.'] = '看看羅賓的示範，隨時都能略過。',
    ['MOVE AROUND'] = '自由移動', ['DOUBLE-TAP TO DASH'] = '連按兩下衝刺',
    ['JUMP'] = '跳躍', ['THREE-HIT COMBO'] = '三段連擊', ['AERIAL ATTACK'] = '空中攻擊',
    ['JOIN, PAUSE, RETURN'] = '加入、暫停與返回',
    ['Use the stick or D-pad.'] = '使用左類比搖桿或方向鍵。',
    ['Move up and down to line up a hit.'] = '上下移動，對準敵人再出手。',
    ['Tap a direction twice, quickly.'] = '快速連按同一方向兩下。',
    ['Add an attack for a dash strike.'] = '衝刺時按攻擊，就能使出衝刺攻擊。',
    ['Tap for a hop. Hold to jump higher.'] = '輕按小跳，按住就能跳得更高。',
    ['Keep moving while you are in the air.'] = '在空中也能繼續移動。',
    ['Tap attack again to keep the combo going.'] = '連續按攻擊，接出完整連段。',
    ['The third hit knocks enemies down.'] = '第三擊能擊倒敵人。',
    ['Jump, then press attack.'] = '先跳起來，再按攻擊。',
    ['Robin follows up with a flying kick.'] = '羅賓會使出飛踢！',
    ['B or RB throws a returning birdarang.'] = '按 B 或 RB 投擲會飛回來的鳥飛鏢。',
    ['Special moves use 30 energy.'] = '特殊技消耗 30 點能量。',
    ['Y unleashes your second power.'] = '按 Y 施展第二招式。',
    ['This move uses 40 energy.'] = '這招消耗 40 點能量。',
    ['RT unleashes your ultimate.'] = '按 RT 施展必殺技。',
    ['Fill your energy bar to 100 first.'] = '先把能量累積到 100 點。',
    ['Menu / Enter joins or pauses the game.'] = 'Menu／Enter：加入或暫停遊戲。',
    ['When paused, View / Esc returns to the menu.'] = '暫停時按 View／Esc，即可回主選單。',
    ['LEVEL MAP'] = '關卡地圖',
    ['RESET PROGRESS'] = '重設進度',
    ['LEVEL {level} CLEARED!'] = '第 {level} 關過關！',
    ['{count} / 4 LEVELS CLEARED'] = '已完成 {count}／4 關',
    ['LEVEL {level}'] = '第 {level} 關',
    ['CLEARED'] = '已過關', ['AVAILABLE'] = '可挑戰', ['LOCKED'] = '尚未解鎖',
    ['4 WAVES / {boss}'] = '4 波敵人／頭目：{boss}',
    ['Clear {level} to unlock.'] = '完成「{level}」即可解鎖。',
    ['Cleared! Replay this level anytime.'] = '已過關！隨時都能再次挑戰。',
    ['Defeat the boss to unlock the next level.'] = '擊敗頭目，即可解鎖下一關。',
    ['Defeat Slade and save Jump City.'] = '擊敗史萊德，拯救雀躍城！',
    ['REPLAY LEVEL'] = '再次挑戰', ['PLAY LEVEL'] = '開始挑戰', ['BACK'] = '返回',
    ['SAVED IN THIS BROWSER'] = '進度已儲存於此瀏覽器',
    ['SAVING UNAVAILABLE - SESSION ONLY'] = '無法儲存，目前僅保留本次進度',
    ['SESSION PROGRESS'] = '目前僅保留本次遊玩進度',
    ['MOVE: SELECT   A / SPACE: PLAY   R / Y: RESET'] = '方向：選擇   A／SPACE：挑戰   R／Y：重設',
    ['RESET PROGRESS?'] = '要重設進度嗎？',
    ['All cleared levels will be locked again.'] = '重設後，已完成的關卡將重新上鎖。',
    ['Level 1 will remain available.'] = '第一關仍可遊玩。',
    ['KEEP PROGRESS'] = '保留進度', ['RESET'] = '重設',
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
