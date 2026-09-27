-- Brief sourced quotations are identified in docs/level-identities.md.
-- All other lines and every Taiwan/Japanese translation are original adaptations.
return {
    -- Cinderblock is normally nonverbal: these are original sound captions.
    boss={
        encounter={{ 'GRRR...', '嗚吼……', "グルル…" },{ 'HRRRAAAH!', '吼啊啊！', "グオオオッ！" },{ '(HEAVY STONE FOOTSTEPS)', '（沉重的石頭腳步聲）', "（重い石の足音）" }},
        special={{ 'GRAAAAH!', '吼啊！', "ガアアアッ！" },{ '(CONCRETE SPLITTING)', '（水泥地面裂開）', "（コンクリートが裂ける音）" },{ '(GROUND SHAKING ROAR)', '（震動地面的怒吼）', "（地を揺らす咆哮）" }},
        low_health={{ 'GRR... RAAAH!', '嗚……吼啊！', "グルル…ガアッ！" },{ '(ANGRY STONE RUMBLE)', '（憤怒的石塊轟鳴）', "（怒れる石のうなり）" },{ '(CONCRETE CREAKING)', '（混凝土嘎嘎作響）', "（コンクリートがきしむ音）" }},
        down={{ 'URRRGH...', '嗚呃……', "ウググ…" },{ '(FALLING RUBBLE)', '（碎石崩落）', "（崩れ落ちる瓦礫）" },{ '(ONE LAST LOW GROWL)', '（最後一聲低吼）', "（最後の低いうなり）" }},
    },
    mammoth={
        encounter={{ 'YOUR WORST NIGHTMARE!', '你最可怕的惡夢！', "お前の最悪の悪夢だ！" },{ 'THIS DOCK BELONGS TO ME!', '這座碼頭歸我管！', "この埠頭は俺のものだ！" },{ 'SMALL HEROES. BIG MISTAKE.', '小小英雄，大大錯誤。', "小さなヒーロー、大きな間違い。" }},
        special={{ 'OUT OF MY WAY!', '給我讓開！', "どけ！" },{ 'I BREAK THE WHOLE DOCK!', '我把整座碼頭拆掉！', "埠頭ごと壊してやる！" },{ 'TRY STOPPING THIS!', '有本事就擋下來！', "これを止めてみろ！" }},
        low_health={{ 'NOW YOU MADE ME MAD!', '這下你惹火我了！', "怒らせたな！" },{ 'STILL STRONGER THAN YOU!', '我還是比你強！', "まだ俺の方が強い！" },{ 'I AM NOT DONE SMASHING!', '我還沒砸夠！', "まだ壊し足りない！" }},
        down={{ 'THAT DOCK WAS RIGGED!', '這碼頭一定有問題！', "この埠頭、細工してたな！" },{ 'NO MORE LITTLE HEROES...', '別再來小英雄了……', "小さなヒーローはもう勘弁だ…" },{ 'NEED A BIGGER LUNCH...', '得多吃一點……', "もっと飯が必要だ…" }},
    },
    jinx={
        encounter={{ 'ATTACK PATTERN ALPHA!', '阿爾法攻擊陣形！', "攻撃パターン、アルファ！" },{ 'YOUR LUCK JUST RAN OUT.', '你的好運到頭了。', "運が尽きたわね。" },{ 'THIS FACTORY HAS BAD LUCK.', '這座工廠運氣可不好。', "この工場は不運だらけよ。" }},
        special={{ 'WATCH YOUR STEP, HEROES.', '英雄們，小心腳下。', "足元に気をつけて、ヒーロー。" },{ 'THREE HEXES. NO EXCUSES.', '三道咒術，不准找藉口。', "呪印は三つ。言い訳無用。" },{ 'LET THE FLOOR BETRAY YOU.', '讓地板背叛你吧。', "床に裏切られるがいいわ。" }},
        low_health={{ 'LUCK CAN STILL CHANGE.', '運氣隨時會變。', "運はまだ変わるわ。" },{ 'DO NOT CALL THAT LUCKY.', '別以為那叫幸運。', "幸運だなんて言わないで。" },{ 'ONE MORE HEX WILL DO.', '再一道咒術就夠了。', "あと一つ呪えば十分。" }},
        down={{ 'ONE VERY UNLUCKY DAY.', '真是倒楣的一天。', "とことんついてない日ね。" },{ 'THE ODDS WERE WRONG...', '機率算錯了……', "確率が間違ってた…" },{ 'THIS IS NOT MY LAST HEX.', '我的咒術還沒結束。', "これが最後の呪いじゃないわ。" }},
    },
    slade={
        encounter={{ "I'VE CHOSEN YOU.", '我選中你了。', "お前を選んだ。" },{ 'EVERY EXIT IS MY DESIGN.', '每個出口都由我設計。', "出口はすべて私の設計だ。" },{ 'SHOW ME WHAT YOU LEARNED.', '讓我看看你學會了什麼。', "学んだことを見せてもらおう。" }},
        special={{ 'YOU WATCHED THE WRONG SIDE.', '你注意錯方向了。', "見る方向を間違えたな。" },{ 'ONE OPENING IS ALL I NEED.', '我只需要一個破綻。', "隙は一つあればいい。" },{ 'YOUR NEXT STEP IS MINE.', '你的下一步由我掌握。', "次の一歩も私のものだ。" }},
        low_health={{ 'A USEFUL DEMONSTRATION.', '很有用的示範。', "有益な実演だ。" },{ 'YOU HAVE MY ATTENTION.', '你引起我的注意了。', "私の関心を引いたな。" },{ 'THE LESSON IS NOT OVER.', '這堂課還沒結束。', "授業はまだ終わらない。" }},
        down={{ 'THIS CHANGES NOTHING.', '這改變不了任何事。', "何も変わりはしない。" },{ 'WE WILL FINISH THIS LATER.', '我們改天再算這筆帳。', "決着は後でつけよう。" },{ 'KEEP PRACTICING, ROBIN.', '繼續練習吧，羅賓。', "練習を続けろ、ロビン。" }},
    },
    madmod={
        encounter={{ 'OFF TO CLASS!', '上課去吧！', "授業へ行け！" },{ 'NO RUNNING IN MY SCHOOL!', '我的學校不准奔跑！', "私の学校では走るな！" },{ 'DEARS, YOUR LESSON STARTS NOW!', '親愛的，現在開始上課！', "さあ諸君、授業開始だ！" }},
        special={{ 'EYES ON THE SCREENS, DUCKIES!', '小乖乖，看著螢幕！', "画面に注目だ、かわいい子たち！" },{ 'DETENTION HAS A LOVELY VIEW!', '留校察看的風景真美！', "居残りの眺めは最高だぞ！" },{ 'DO KEEP UP WITH THE PATTERN!', '可要跟上這個圖案喔！', "模様についてくるのだ！" }},
        low_health={{ 'SUCH APPALLING MANNERS!', '真是糟糕的禮貌！', "なんとひどい行儀だ！" },{ 'YOU HAVE NOT BEEN DISMISSED!', '還沒准你們下課！', "まだ帰ってよいとは言ってない！" },{ 'MY CANE WILL SORT THIS OUT!', '我的手杖會解決這一切！', "この杖で片づけてやる！" }},
        down={{ 'CLASS IS... DISMISSED.', '現在……下課。', "授業は…終わりだ。" },{ 'MY LOVELY SCHOOL...', '我可愛的學校……', "私の美しい学校が…" },{ 'THOSE DREADFUL CHILDREN!', '這些討厭的孩子！', "まったくひどい子供たちだ！" }},
    },
    blood={
        encounter={{ 'YOU CANNOT DEFEAT THE HEADMASTER.', '你們打不倒校長。', "校長には勝てない。" },{ 'WELCOME TO YOUR FINAL LESSON.', '歡迎來到最後一堂課。', "最後の授業へようこそ。" },{ 'THE ACADEMY DEMANDS OBEDIENCE.', '學院要求絕對服從。', "学院は服従を求める。" }},
        special={{ 'YOUR WILL IS MINE TO TAKE.', '你們的意志由我奪取。', "お前の意志は私が奪う。" },{ 'EMPTY YOUR MINDS. OBEY.', '清空思緒，服從命令。', "心を空にしろ。従え。" },{ 'YOUR POWER SERVES MY SCHOOL.', '你們的力量為學院效力。', "お前の力は我が校に仕える。" }},
        low_health={{ 'WHY DO YOU STILL RESIST?', '為什麼還要反抗？', "なぜまだ逆らう？" },{ 'YOU WILL LEARN OBEDIENCE!', '你們終究會學會服從！', "服従を教えてやる！" },{ 'NO STUDENT OUTGROWS ME!', '沒有學生能超越我！', "私を超える生徒などいない！" }},
        down={{ 'IMPOSSIBLE. YOUR WILL...', '不可能，你們的意志……', "ありえない。その意志が…" },{ 'MY PERFECT ACADEMY...', '我的完美學院……', "私の完璧な学院が…" },{ 'THIS LESSON CANNOT END!', '這堂課不能結束！', "この授業は終わらせない！" }},
    },
    blackfire={
        encounter={{ 'BOW BEFORE YOUR EMPRESS.', '向你們的女王低頭。', "女帝の前にひざまずきなさい。" },{ 'THIS THRONE IS MINE, SISTER.', '妹妹，這個王座是我的。', "妹よ、この王座は私のもの。" },{ 'THE JEWEL OF CHARTA IS MINE.', '查塔寶石，我的力量。', "チャルタの宝石は私のものよ。" }},
        special={{ 'THE JEWEL MAKES ME STRONGER!', '寶石讓我更加強大！', "宝石が私を強くする！" },{ 'TRY TO OUTSHINE THIS, SISTER!', '妹妹，有本事比我更耀眼！', "これ以上に輝けるかしら、妹よ！" },{ 'A ROYAL WELCOME FROM ABOVE!', '接受從天而降的皇家歡迎！', "上空から王家のお出迎えよ！" }},
        low_health={{ 'YOU WILL NOT TAKE MY CROWN!', '別想奪走我的王冠！', "王冠は渡さない！" },{ 'THE JEWEL WILL NOT FAIL ME!', '寶石不會讓我失望！', "宝石は私を裏切らない！" },{ 'I AM STILL THE BETTER SISTER!', '我仍然是比較優秀的姊姊！', "優れた姉は私よ！" }},
        down={{ 'MY THRONE... MY POWER...', '我的王座……我的力量……', "私の王座…私の力…" },{ 'THIS IS NOT YOUR VICTORY!', '這不算你的勝利！', "あなたの勝利じゃない！" },{ 'WE ARE NOT FINISHED, SISTER.', '妹妹，我們還沒完。', "まだ終わってないわ、妹よ。" }},
    },
    trigon={
        encounter={{ 'YOUR WORLD IS ENDED!', '你們的世界已經終結！', "お前たちの世界は終わりだ！" },{ 'ALL EARTH BOWS TO TRIGON.', '整個地球臣服於三宮魔。', "地球はトライゴンにひれ伏す。" },{ 'HOPE IS SMALL BEFORE ME.', '希望在我面前渺小無比。', "我の前では希望など微小。" }},
        special={{ 'FOUR EYES. NO HIDING PLACE.', '四隻眼睛，無處可藏。', "四つの眼。隠れ場はない。" },{ 'THE EARTH WILL BURN AGAIN.', '大地將再次燃燒。', "大地は再び燃える。" },{ 'MY GAZE UNMAKES YOUR WORLD.', '我的目光將摧毀世界。', "我の眼光が世界を消す。" }},
        low_health={{ 'YOU CANNOT UNMAKE A GOD!', '你們無法摧毀神！', "神を消すことなどできぬ！" },{ 'I AM STILL YOUR DOOM!', '我依然是你們的末日！', "我こそが破滅だ！" },{ 'THE FLAMES WILL OBEY ME!', '火焰必須服從我！', "炎は我に従え！" }},
        down={{ 'THIS WORLD WAS MINE...', '這世界本來屬於我……', "この世界は我のものだった…" },{ 'YOUR HOPE... IMPOSSIBLE!', '你們的希望……不可能！', "その希望…ありえぬ！" },{ 'TREMBLE AT MY RETURN!', '為我的歸來顫抖吧！', "我の帰還に震えるがいい！" }},
    },
} :: {[string]:{[string]:{{string}}}}
