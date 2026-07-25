#!/usr/bin/env python3
"""Build Scripts/Resources/asia_latam_localizations.json from embedded translations."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EN_PATH = ROOT / ".tmp/en_source_strings.json"
OUT_PATH = ROOT / "Scripts/Resources/asia_latam_localizations.json"

T: dict[str, dict[str, str]] = {}


def add(key: str, ja: str, ko: str, pt: str, zh: str) -> None:
    T[key] = {"ja": ja, "ko": ko, "pt-BR": pt, "zh-Hant": zh}


# --- Format / passthrough ---
add("", "", "", "", "")
add("%@%@", "%1$@%2$@", "%1$@%2$@", "%1$@%2$@", "%1$@%2$@")
add("%@%@%@", "%1$@%2$@%3$@", "%1$@%2$@%3$@", "%1$@%2$@%3$@", "%1$@%2$@%3$@")
add("%lld", "%lld", "%lld", "%lld", "%lld")
add("%lld life remaining", "残りライフ %lld", "남은 목숨 %lld", "%lld vida restante", "剩餘生命 %lld")
add("%lld lives remaining", "残りライフ %lld", "남은 목숨 %lld", "%lld vidas restantes", "剩餘生命 %lld")
add("0%", "0%", "0%", "0%", "0%")
add("100%", "100%", "100%", "100%", "100%")
add("x%lld", "x%lld", "x%lld", "x%lld", "x%lld")

# --- System / accessibility ---
add("Close", "閉じる", "닫기", "Fechar", "關閉")
add(
    "Game Center is unavailable for this account.",
    "このアカウントではGame Centerを利用できません。",
    "이 계정에서는 Game Center를 사용할 수 없어요.",
    "O Game Center não está disponível para esta conta.",
    "此帳號無法使用 Game Center。",
)
add(
    "Game Center leaderboard is available on iOS and tvOS.",
    "Game CenterリーダーボードはiOSとtvOSで利用できます。",
    "Game Center 리더보드는 iOS와 tvOS에서 사용할 수 있어요.",
    "O ranking do Game Center está disponível no iOS e tvOS.",
    "Game Center 排行榜可在 iOS 與 tvOS 上使用。",
)
add(
    "Game Center leaderboard is not available on this device.",
    "このデバイスではGame Centerリーダーボードを利用できません。",
    "이 기기에서는 Game Center 리더보드를 사용할 수 없어요.",
    "O ranking do Game Center não está disponível neste dispositivo.",
    "此裝置無法使用 Game Center 排行榜。",
)
add("Opens app rating prompt", "App Storeの評価画面を開きます", "앱 평가 창을 엽니다", "Abre a tela de avaliação na App Store", "開啟 App Store 評分提示")
add("Screenshot capture ready", "スクリーンショット撮影の準備完了", "스크린샷 촬영 준비 완료", "Captura de tela pronta", "螢幕截圖擷取就緒")
add("Shows Game Center leaderboard", "Game Centerリーダーボードを表示", "Game Center 리더보드를 표시합니다", "Mostra o ranking do Game Center", "顯示 Game Center 排行榜")
add(
    "Sign in to Game Center to view the leaderboard.",
    "リーダーボードを見るにはGame Centerにサインインしてください。",
    "리더보드를 보려면 Game Center에 로그인하세요.",
    "Entre no Game Center para ver o ranking.",
    "請登入 Game Center 以查看排行榜。",
)
add("Starts the game", "ゲームを開始", "게임을 시작합니다", "Inicia o jogo", "開始遊戲")

# --- About ---
add("about_also_supporting_header", "こちらも支援", "함께 후원", "Também apoiamos", "也支持")
add(
    "about_ammec_footer",
    "収益の10%はAMMECに寄付されます。AMMECは、身体障害のある方の自立と社会参加を支援し、家族とコミュニティを支える団体です。",
    "수익의 10%는 AMMEC에 기부됩니다. AMMEC는 신체 장애가 있는 분들의 자립과 사회 통합, 가족과 지역사회를 지원하는 단체예요.",
    "10% dos valores vão para a AMMEC, uma associação que promove autonomia e integração social de pessoas com deficiência física, apoiando famílias e fortalecendo a comunidade.",
    "收益的 10% 將捐給 AMMEC，這個協會促進身心障礙者的自主與社會融入，支持家庭並凝聚社群。",
)
add("about_ammec_title", "AMMEC", "AMMEC", "AMMEC", "AMMEC")
add("about_app_subtitle", "アプリ情報、ヒント、ヘルプ", "앱 정보, 팁, 도움말", "Informações do app, dicas e ajuda", "App 資訊、提示與說明")
add("about_app_title", "RetroRapid!", "RetroRapid!", "RetroRapid!", "RetroRapid!")
add("about_arcticonference_subtitle", "最高にクールなカンファレンスのために", "가장 멋진 컨퍼런스를 위해", "Pela conferência mais irada", "獻給最酷的開發者大會")
add("about_arcticonference_title", "ARCtic Conference", "ARCtic Conference", "ARCtic Conference", "ARCtic Conference")
add("about_connect_header", "つながろう！", "함께해요!", "Vamos nos conectar!", "一起連結！")
add("about_credits_header", "クレジット", "크레딧", "Créditos", "製作群")
add("about_font_license", "SIL Open Font License 1.1 の下でライセンス", "SIL Open Font License 1.1 하에 라이선스", "Licenciada sob a SIL Open Font License 1.1", "依 SIL Open Font License 1.1 授權")
add("about_font_press_start", "Press Start 2P", "Press Start 2P", "Press Start 2P", "Press Start 2P")
add("about_footer_location", "フィンランド・オウル", "핀란드 오ulu", "Oulu, Finlândia", "芬蘭奥盧")
add("about_footer_love", "ARCticから愛を込めて ❤️", "ARCtic에서 사랑을 담아 ❤️", "Lançado com amor ❤️ da ARCtic", "由 ARCtic 帶著愛 ❤️ 推出")
add(
    "about_footer_thanks",
    "プレイしてくれた皆さん、ボタンを押す勇気をくれてありがとう。",
    "게임을 즐겨 주고 버튼을 누르도록 격려해 준 모든 분께 감사합니다.",
    "Obrigado a todos que jogaram e me incentivaram a apertar o botão.",
    "感謝所有玩過遊戲、並鼓勵我按下發佈按鈕的人。",
)
add("about_giving_back_header", "還元", "기부", "Retribuir", "回饋社會")
add("about_helm_subtitle", "App Store Connectを管理するネイティブアプリ", "App Store Connect를 관리하는 네이티브 앱", "Um app nativo para gerenciar o App Store Connect", "管理 App Store Connect 的原生 App")
add("about_helm_title", "Shipped with Helm!", "Shipped with Helm!", "Shipped with Helm!", "Shipped with Helm!")
add("about_link_blog", "Accessibility up to 11!", "Accessibility up to 11!", "Accessibility up to 11!", "Accessibility up to 11!")
add("about_link_bluesky", "BlueSky", "BlueSky", "BlueSky", "BlueSky")
add("about_link_linkedin", "LinkedIn", "LinkedIn", "LinkedIn", "LinkedIn")
add("about_link_mastodon", "Mastodon", "Mastodon", "Mastodon", "Mastodon")
add("about_link_twitter", "X (Twitter)", "X (Twitter)", "X (Twitter)", "X (Twitter)")
add("about_rate_hint", "App Storeのレビューページを開きます", "App Store 리뷰 페이지를 엽니다", "Abre a página de avaliação na App Store", "開啟 App Store 評論頁面")
add("about_rate_title", "RetroRapid!を評価", "RetroRapid! 평가하기", "Avalie o RetroRapid!", "為 RetroRapid! 評分")
add("about_swift_for_swifts_title", "Swift for Swifts", "Swift for Swifts", "Swift for Swifts", "Swift for Swifts")
add("about_title", "このアプリについて", "정보", "Sobre", "關於")

# NOTE: Remaining keys loaded from companion data module
import sys
from pathlib import Path as _Path

sys.path.insert(0, str(_Path(__file__).resolve().parent))
from asia_latam_translations_data import TRANSLATIONS

T.update(TRANSLATIONS)

def main() -> None:
    en = json.loads(EN_PATH.read_text())
    missing = [k for k in en if k not in T]
    extra = [k for k in T if k not in en]
    if missing:
        raise SystemExit(f"Missing translations for {len(missing)} keys: {missing[:10]}")
    if extra:
        print(f"Warning: {len(extra)} extra keys in bundle")
    OUT_PATH.write_text(json.dumps(T, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {len(T)} keys to {OUT_PATH}")


if __name__ == "__main__":
    main()
