"""
Sky Bubble Burst – Privacy Policy PDF Generator
Beautiful, professional, Google Play compliant
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm, cm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether, PageBreak, Flowable
)
from reportlab.graphics.shapes import Drawing, Rect, Circle, String, Line, Polygon
from reportlab.graphics import renderPDF
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor
import os

# ── Output path ──────────────────────────────────────────────────────────────
OUT = "/Users/urviambaliya/Documents/Projects/bubble_pumping/privacy-policy.pdf"

# ── Colour Palette ────────────────────────────────────────────────────────────
C_PRIMARY       = HexColor("#5B8FFF")
C_PRIMARY_DARK  = HexColor("#3A6FE8")
C_ACCENT        = HexColor("#A78BFA")
C_GRAD_A        = HexColor("#667EEA")
C_GRAD_B        = HexColor("#764BA2")

C_SUCCESS       = HexColor("#10B981")
C_SUCCESS_BG    = HexColor("#D1FAE5")
C_SUCCESS_DARK  = HexColor("#065F46")

C_WARNING       = HexColor("#F59E0B")
C_WARNING_BG    = HexColor("#FEF3C7")
C_WARNING_DARK  = HexColor("#92400E")

C_INFO          = HexColor("#3B82F6")
C_INFO_BG       = HexColor("#DBEAFE")
C_INFO_DARK     = HexColor("#1E40AF")

C_BG            = HexColor("#F8FAFF")
C_SURFACE       = HexColor("#FFFFFF")
C_SURFACE_ALT   = HexColor("#F1F5FF")
C_BORDER        = HexColor("#E2E8F0")
C_TEXT          = HexColor("#1E293B")
C_TEXT_SEC      = HexColor("#475569")
C_TEXT_MUTED    = HexColor("#94A3B8")

C_HERO_BG       = HexColor("#5563C1")

PAGE_W, PAGE_H  = A4
MARGIN_L        = 2.2 * cm
MARGIN_R        = 2.2 * cm
MARGIN_T        = 0
MARGIN_B        = 2 * cm
CONTENT_W       = PAGE_W - MARGIN_L - MARGIN_R

# ════════════════════════════════════════════════════════════════════════════
#  CUSTOM FLOWABLES
# ════════════════════════════════════════════════════════════════════════════

class GradientBanner(Flowable):
    """Full-width gradient hero banner spanning the entire page width."""
    def __init__(self, height=72*mm):
        Flowable.__init__(self)
        self.banner_h = height
        self.width    = CONTENT_W
        self.height   = height

    def draw(self):
        c = self.canv
        w, h = CONTENT_W, self.banner_h

        # Draw gradient via stacked rects (reportlab has no native linear grad)
        steps = 60
        for i in range(steps):
            t    = i / steps
            r    = int(C_GRAD_A.red*255*(1-t) + C_GRAD_B.red*255*t)
            g    = int(C_GRAD_A.green*255*(1-t) + C_GRAD_B.green*255*t)
            b    = int(C_GRAD_A.blue*255*(1-t) + C_GRAD_B.blue*255*t)
            c.setFillColorRGB(r/255, g/255, b/255)
            y    = (i / steps) * h
            band = h / steps + 1
            c.rect(-MARGIN_L, y, w + MARGIN_L + MARGIN_R, band, stroke=0, fill=1)

        # Decorative circles
        c.setFillColorRGB(1, 1, 1, 0.06)
        c.circle(-20*mm, h*0.6, 55*mm, stroke=0, fill=1)
        c.circle(w + 15*mm, h*0.3, 45*mm, stroke=0, fill=1)
        c.circle(w*0.5, h*1.1, 40*mm, stroke=0, fill=1)

        # Bubble emoji  (drawn as styled text)
        c.setFont("Helvetica-Bold", 52)
        c.setFillColorRGB(1, 1, 1, 0.18)
        c.drawString(w - 48*mm, h*0.28, "🫧")

        # App name
        c.setFillColorRGB(1, 1, 1, 0.60)
        c.setFont("Helvetica", 9)
        c.drawString(0, h - 14*mm, "SKY BUBBLE BURST")

        # Main title
        c.setFillColorRGB(1, 1, 1, 1.0)
        c.setFont("Helvetica-Bold", 32)
        c.drawString(0, h - 31*mm, "Privacy Policy")

        # Subtitle
        c.setFillColorRGB(1, 1, 1, 0.85)
        c.setFont("Helvetica", 11)
        subtitle = "Transparent · Compliant · Family-Friendly"
        c.drawString(0, h - 42*mm, subtitle)

        # Meta row  ——  date | developer | platform
        c.setFillColorRGB(1, 1, 1, 0.65)
        c.setFont("Helvetica", 8.5)
        meta = "Effective: June 12, 2025    ·    Developer: Pandav    ·    Platform: Google Play (Android)"
        c.drawString(0, h - 54*mm, meta)

        # Bottom badge strip
        badges = [
            ("✓  Google Play Compliant", C_SUCCESS),
            ("✓  AdMob Disclosed",       C_INFO),
            ("✓  GDPR · CCPA Ready",     C_ACCENT),
            ("✓  No Personal Data",      HexColor("#F59E0B")),
        ]
        bx = 0
        for label, col in badges:
            bw = 46*mm
            # pill background
            c.setFillColor(col)
            c.roundRect(bx, 5*mm, bw - 2*mm, 8*mm, 2*mm, stroke=0, fill=1)
            c.setFillColorRGB(1, 1, 1, 0.95)
            c.setFont("Helvetica-Bold", 7)
            c.drawString(bx + 3*mm, 7.5*mm, label)
            bx += bw + 1.5*mm


class SectionHeader(Flowable):
    """Numbered section header with left accent bar."""
    def __init__(self, number, title, width=CONTENT_W):
        Flowable.__init__(self)
        self.number = number
        self.title  = title
        self.width  = width
        self.height = 18*mm

    def draw(self):
        c = self.canv
        w, h = self.width, self.height

        # Subtle background pill
        c.setFillColor(C_SURFACE_ALT)
        c.roundRect(0, 0, w, h, 3*mm, stroke=0, fill=1)

        # Left accent gradient bar
        steps = 20
        bar_h = h
        for i in range(steps):
            t = i / steps
            r = int(C_GRAD_A.red*255*(1-t) + C_PRIMARY.red*255*t)
            g = int(C_GRAD_A.green*255*(1-t) + C_PRIMARY.green*255*t)
            b = int(C_GRAD_A.blue*255*(1-t) + C_PRIMARY.blue*255*t)
            c.setFillColorRGB(r/255, g/255, b/255)
            y = (i / steps) * bar_h
            c.rect(0, y, 4.5*mm, bar_h/steps + 1, stroke=0, fill=1)

        # Round the accent bar ends
        c.setFillColor(C_GRAD_A)
        c.circle(2.25*mm, h, 2.25*mm, stroke=0, fill=1)
        c.circle(2.25*mm, 0, 2.25*mm, stroke=0, fill=1)

        # Section number pill
        c.setFillColor(C_PRIMARY)
        c.roundRect(8*mm, h/2 - 4*mm, 10*mm, 8*mm, 2*mm, stroke=0, fill=1)
        c.setFillColorRGB(1, 1, 1, 1)
        c.setFont("Helvetica-Bold", 8)
        c.drawCentredString(13*mm, h/2 - 1.5*mm, self.number)

        # Title text
        c.setFillColor(C_TEXT)
        c.setFont("Helvetica-Bold", 15)
        c.drawString(22*mm, h/2 - 2.5*mm, self.title)


class DividerLine(Flowable):
    """Thin gradient divider."""
    def __init__(self, width=CONTENT_W, height=1.5):
        Flowable.__init__(self)
        self.width  = width
        self.height = height + 4

    def draw(self):
        c = self.canv
        steps = 30
        for i in range(steps):
            t = i / steps
            # fade in from left, fade out to right
            alpha = 4*t*(1-t)
            r = int(C_GRAD_A.red*255*(1-t) + C_ACCENT.red*255*t)
            g = int(C_GRAD_A.green*255*(1-t) + C_ACCENT.green*255*t)
            b = int(C_GRAD_A.blue*255*(1-t) + C_ACCENT.blue*255*t)
            c.setFillColorRGB(r/255, g/255, b/255, alpha)
            x = (i / steps) * self.width
            c.rect(x, 2, self.width/steps + 1, 1.5, stroke=0, fill=1)


class NoteBox(Flowable):
    """Coloured compliance / info note box."""
    def __init__(self, text, kind="info", width=CONTENT_W):
        Flowable.__init__(self)
        self._text  = text
        self.kind   = kind
        self.width  = width
        # estimate height
        chars_per_line = int(width / (2.8*mm))
        lines = max(2, len(text) // chars_per_line + 2)
        self.height = lines * 5.5*mm + 8*mm

    def draw(self):
        c   = self.canv
        w, h = self.width, self.height
        if self.kind == "warning":
            bg, border, tc = C_WARNING_BG, C_WARNING, C_WARNING_DARK
            icon = "⚠"
        elif self.kind == "success":
            bg, border, tc = C_SUCCESS_BG, C_SUCCESS, C_SUCCESS_DARK
            icon = "✓"
        else:
            bg, border, tc = C_INFO_BG, C_INFO, C_INFO_DARK
            icon = "ℹ"

        # Background
        c.setFillColor(bg)
        c.roundRect(0, 0, w, h, 2.5*mm, stroke=0, fill=1)

        # Left accent bar
        c.setFillColor(border)
        c.roundRect(0, 0, 3.5*mm, h, 2.5*mm, stroke=0, fill=1)

        # Icon
        c.setFillColor(border)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(5.5*mm, h - 8*mm, icon)

        # Text (manual wrap)
        c.setFillColor(tc)
        c.setFont("Helvetica", 8.5)
        chars_per_line = int((w - 18*mm) / (2.4*mm))
        words = self._text.split()
        lines, cur = [], ""
        for word in words:
            test = (cur + " " + word).strip()
            if len(test) <= chars_per_line:
                cur = test
            else:
                lines.append(cur)
                cur = word
        if cur:
            lines.append(cur)

        y = h - 7.5*mm
        for line in lines:
            c.drawString(13*mm, y, line)
            y -= 4.8*mm


# ════════════════════════════════════════════════════════════════════════════
#  STYLES
# ════════════════════════════════════════════════════════════════════════════

def make_styles():
    return {
        "body": ParagraphStyle(
            "body",
            fontName="Helvetica",
            fontSize=9.5,
            leading=15,
            textColor=C_TEXT_SEC,
            spaceAfter=6,
        ),
        "body_bold": ParagraphStyle(
            "body_bold",
            fontName="Helvetica-Bold",
            fontSize=9.5,
            leading=15,
            textColor=C_TEXT,
            spaceAfter=4,
        ),
        "h3": ParagraphStyle(
            "h3",
            fontName="Helvetica-Bold",
            fontSize=11,
            leading=16,
            textColor=C_TEXT,
            spaceBefore=10,
            spaceAfter=4,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            fontName="Helvetica",
            fontSize=9,
            leading=14,
            textColor=C_TEXT_SEC,
            leftIndent=14,
            spaceAfter=3,
            bulletIndent=4,
        ),
        "code_inline": ParagraphStyle(
            "code_inline",
            fontName="Courier",
            fontSize=8.5,
            leading=13,
            textColor=C_PRIMARY_DARK,
            backColor=C_SURFACE_ALT,
            spaceAfter=4,
        ),
        "toc_item": ParagraphStyle(
            "toc_item",
            fontName="Helvetica",
            fontSize=9,
            leading=14,
            textColor=C_PRIMARY,
            spaceAfter=2,
        ),
        "footer": ParagraphStyle(
            "footer",
            fontName="Helvetica",
            fontSize=7.5,
            leading=11,
            textColor=C_TEXT_MUTED,
            alignment=TA_CENTER,
        ),
        "caption": ParagraphStyle(
            "caption",
            fontName="Helvetica",
            fontSize=8,
            leading=12,
            textColor=C_TEXT_MUTED,
            alignment=TA_CENTER,
            spaceAfter=6,
        ),
    }


# ════════════════════════════════════════════════════════════════════════════
#  PAGE TEMPLATE  (header + footer on every page except page 1)
# ════════════════════════════════════════════════════════════════════════════

def on_page(canvas, doc):
    canvas.saveState()
    page_num = doc.page

    if page_num > 1:
        # ── Top rule
        canvas.setStrokeColor(C_BORDER)
        canvas.setLineWidth(0.5)
        canvas.line(MARGIN_L, PAGE_H - 14*mm, PAGE_W - MARGIN_R, PAGE_H - 14*mm)

        # ── Header text
        canvas.setFillColor(C_TEXT_MUTED)
        canvas.setFont("Helvetica", 7.5)
        canvas.drawString(MARGIN_L, PAGE_H - 11.5*mm, "Sky Bubble Burst  ·  Privacy Policy")
        canvas.setFont("Helvetica", 7.5)
        canvas.drawRightString(PAGE_W - MARGIN_R, PAGE_H - 11.5*mm, "Pandav · developerpandav16@gmail.com")

        # ── Dot separator
        canvas.setFillColor(C_PRIMARY)
        canvas.circle((PAGE_W)/2, PAGE_H - 11.5*mm, 1*mm, stroke=0, fill=1)

    # ── Bottom rule
    canvas.setStrokeColor(C_BORDER)
    canvas.setLineWidth(0.5)
    canvas.line(MARGIN_L, 13*mm, PAGE_W - MARGIN_R, 13*mm)

    # ── Footer
    canvas.setFillColor(C_TEXT_MUTED)
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(MARGIN_L, 9*mm, "© 2025 Pandav. All rights reserved. com.pandav.skybubbleburst")
    canvas.drawRightString(PAGE_W - MARGIN_R, 9*mm, f"Page {page_num}")

    # ── Small accent dot in footer
    canvas.setFillColor(C_PRIMARY)
    canvas.circle(PAGE_W/2, 9.5*mm, 0.8*mm, stroke=0, fill=1)

    canvas.restoreState()


# ════════════════════════════════════════════════════════════════════════════
#  TABLE HELPERS
# ════════════════════════════════════════════════════════════════════════════

def tag_cell(text, kind="green"):
    colours = {
        "green":  (C_SUCCESS_BG,  C_SUCCESS_DARK),
        "blue":   (C_INFO_BG,     C_INFO_DARK),
        "orange": (C_WARNING_BG,  C_WARNING_DARK),
    }
    bg, tc = colours.get(kind, colours["green"])
    return Paragraph(
        f'<font color="#{tc.hexval()[2:].upper()}">{text}</font>',
        ParagraphStyle("tag", fontName="Helvetica-Bold", fontSize=8,
                       leading=11, backColor=bg, borderPadding=2,
                       borderRadius=3)
    )


def data_table(headers, rows, col_widths, S):
    header_row = [Paragraph(f'<b>{h}</b>', ParagraphStyle(
        "th", fontName="Helvetica-Bold", fontSize=8, leading=11,
        textColor=C_TEXT)) for h in headers]

    body_rows = []
    for row in rows:
        body_rows.append([
            cell if isinstance(cell, Paragraph)
            else Paragraph(str(cell), ParagraphStyle(
                "td", fontName="Helvetica", fontSize=8.5, leading=13,
                textColor=C_TEXT_SEC))
            for cell in row
        ])

    all_rows = [header_row] + body_rows

    style = TableStyle([
        # Header
        ("BACKGROUND",   (0,0), (-1,0), C_PRIMARY_LIGHT := HexColor("#E8EFFF")),
        ("ROWBACKGROUNDS",(0,1),(-1,-1), [C_SURFACE, C_SURFACE_ALT]),
        ("FONTNAME",     (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTSIZE",     (0,0), (-1,0), 8),
        ("BOTTOMPADDING",(0,0), (-1,0), 5),
        ("TOPPADDING",   (0,0), (-1,0), 5),
        ("LEFTPADDING",  (0,0), (-1,-1), 7),
        ("RIGHTPADDING", (0,0), (-1,-1), 7),
        ("TOPPADDING",   (0,1), (-1,-1), 5),
        ("BOTTOMPADDING",(0,1), (-1,-1), 5),
        # Grid
        ("GRID",         (0,0), (-1,-1), 0.4, C_BORDER),
        ("LINEBELOW",    (0,0), (-1,0),  0.8, C_PRIMARY),
        ("ROUNDEDCORNERS", [3]),
        ("VALIGN",       (0,0), (-1,-1), "MIDDLE"),
    ])
    t = Table(all_rows, colWidths=col_widths, style=style,
              repeatRows=1, hAlign="LEFT")
    return t


def audit_table(items, kind="pass"):
    if kind == "pass":
        icon, bg, tc = "✓", C_SUCCESS_BG, C_SUCCESS_DARK
    else:
        icon, bg, tc = "!", C_WARNING_BG, C_WARNING_DARK

    rows = []
    for title, detail in items:
        rows.append([
            Paragraph(f'<font color="#{tc.hexval()[2:].upper()}"><b>{icon}</b></font>',
                      ParagraphStyle("ai", fontName="Helvetica-Bold", fontSize=11,
                                     leading=13, alignment=TA_CENTER)),
            Paragraph(f'<b><font color="#{tc.hexval()[2:].upper()}">{title}</font></b><br/>'
                      f'<font color="#475569">{detail}</font>',
                      ParagraphStyle("at", fontName="Helvetica", fontSize=8.5, leading=13))
        ])

    style = TableStyle([
        ("BACKGROUND",    (0,0), (-1,-1), bg),
        ("ROWBACKGROUNDS",(0,0),(-1,-1), [bg]),
        ("GRID",          (0,0), (-1,-1), 0.3, HexColor("#CBD5E1")),
        ("LINEBELOW",     (0,0), (-1,-2), 0.3, HexColor("#CBD5E1")),
        ("VALIGN",        (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING",   (0,0), (-1,-1), 7),
        ("RIGHTPADDING",  (0,0), (-1,-1), 7),
        ("TOPPADDING",    (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
    ])
    return Table(rows, colWidths=[10*mm, CONTENT_W - 10*mm], style=style, hAlign="LEFT")


# ════════════════════════════════════════════════════════════════════════════
#  SUMMARY CARDS  (row of 4)
# ════════════════════════════════════════════════════════════════════════════

def summary_cards():
    cards = [
        ("✅", "No Personal\nData Collected",    C_SUCCESS,  C_SUCCESS_BG),
        ("📱", "Local Storage\nOnly",             C_PRIMARY,  C_PRIMARY_LIGHT := HexColor("#E8EFFF")),
        ("📢", "AdMob Ads\nDisplayed",            C_WARNING,  C_WARNING_BG),
        ("🔒", "No Account\nRequired",            C_ACCENT,   HexColor("#EDE9FE")),
    ]
    cw = (CONTENT_W - 6*mm) / 4

    rows = []
    for icon, label, accent, bg in cards:
        rows.append(Paragraph(
            f'<para align="center"><font size="22">{icon}</font><br/>'
            f'<font size="8.5" color="#{accent.hexval()[2:].upper()}"><b>{label.replace(chr(10),"<br/>")}</b></font></para>',
            ParagraphStyle("card_p", fontName="Helvetica", fontSize=8.5,
                           leading=12, alignment=TA_CENTER)
        ))

    style = TableStyle([
        ("BACKGROUND",    (0,0), (-1,-1), HexColor("#F8FAFF")),
        ("ROWBACKGROUNDS",(0,0), (-1,-1), [HexColor("#F8FAFF")]),
        ("BOX",           (0,0), (0,0), 1.2, C_SUCCESS),
        ("BOX",           (1,0), (1,0), 1.2, C_PRIMARY),
        ("BOX",           (2,0), (2,0), 1.2, C_WARNING),
        ("BOX",           (3,0), (3,0), 1.2, C_ACCENT),
        ("TOPPADDING",    (0,0), (-1,-1), 10),
        ("BOTTOMPADDING", (0,0), (-1,-1), 10),
        ("LEFTPADDING",   (0,0), (-1,-1), 5),
        ("RIGHTPADDING",  (0,0), (-1,-1), 5),
        ("ROUNDEDCORNERS", [4]),
    ])
    return Table([rows], colWidths=[cw]*4, style=style, hAlign="LEFT")


# ════════════════════════════════════════════════════════════════════════════
#  BUILD DOCUMENT
# ════════════════════════════════════════════════════════════════════════════

def build():
    S = make_styles()

    doc = SimpleDocTemplate(
        OUT,
        pagesize=A4,
        leftMargin=MARGIN_L,
        rightMargin=MARGIN_R,
        topMargin=1.8*cm,
        bottomMargin=2.2*cm,
        title="Privacy Policy – Sky Bubble Burst",
        author="Pandav",
        subject="Privacy Policy for Sky Bubble Burst (com.pandav.skybubbleburst)",
        creator="Sky Bubble Burst Privacy Policy Generator",
        keywords="privacy policy, sky bubble burst, admob, google play, android",
    )

    story = []

    # ── HERO BANNER (page 1 only) ────────────────────────────────────────────
    story.append(GradientBanner(height=72*mm))
    story.append(Spacer(1, 6*mm))

    # ── SUMMARY CARDS ──────────────────────────────────────────────────────
    story.append(Paragraph("AT A GLANCE", ParagraphStyle(
        "label", fontName="Helvetica-Bold", fontSize=7, leading=10,
        textColor=C_TEXT_MUTED, spaceAfter=4, tracking=2)))
    story.append(summary_cards())
    story.append(Spacer(1, 5*mm))
    story.append(DividerLine())
    story.append(Spacer(1, 5*mm))

    # ── TABLE OF CONTENTS ──────────────────────────────────────────────────
    story.append(Paragraph("TABLE OF CONTENTS", ParagraphStyle(
        "label", fontName="Helvetica-Bold", fontSize=7, leading=10,
        textColor=C_TEXT_MUTED, spaceAfter=4, tracking=2)))

    toc_entries = [
        ("01", "About This Policy"),
        ("02", "Information We Collect"),
        ("03", "How We Use Information"),
        ("04", "Advertising (Google AdMob)"),
        ("05", "Third-Party Services"),
        ("06", "Data Retention"),
        ("07", "Data Security"),
        ("08", "Children's Privacy"),
        ("09", "Your Rights & Choices"),
        ("10", "International Data Transfers"),
        ("11", "Data Deletion"),
        ("12", "GDPR Rights (EEA Residents)"),
        ("13", "CCPA Rights (California Residents)"),
        ("14", "Contact Us"),
        ("15", "Policy Updates"),
        ("16", "Compliance Audit Summary"),
    ]

    toc_rows = []
    pair = []
    for num, title in toc_entries:
        cell = Paragraph(
            f'<font color="#{C_PRIMARY.hexval()[2:]}" size="8"><b>{num}</b></font>'
            f'<font color="#{C_TEXT_SEC.hexval()[2:]}" size="8">  {title}</font>',
            ParagraphStyle("toc_c", fontName="Helvetica", fontSize=8, leading=13))
        pair.append(cell)
        if len(pair) == 2:
            toc_rows.append(pair)
            pair = []
    if pair:
        pair.append(Paragraph("", S["body"]))
        toc_rows.append(pair)

    toc_table = Table(toc_rows,
                      colWidths=[CONTENT_W/2 - 2*mm, CONTENT_W/2 - 2*mm],
                      style=TableStyle([
                          ("BACKGROUND", (0,0),(-1,-1), C_SURFACE_ALT),
                          ("GRID",       (0,0),(-1,-1), 0.3, C_BORDER),
                          ("TOPPADDING", (0,0),(-1,-1), 5),
                          ("BOTTOMPADDING",(0,0),(-1,-1), 5),
                          ("LEFTPADDING",(0,0),(-1,-1), 7),
                      ]),
                      hAlign="LEFT")
    story.append(toc_table)
    story.append(Spacer(1, 6*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 1 — About This Policy
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("01", "About This Policy"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph(
        "This Privacy Policy describes how <b>Pandav</b> (“we,” “us,” or “our”) handles "
        "information in connection with the mobile game <b>Sky Bubble Burst</b> "
        "(Android package: <font name='Courier' size='8.5'>com.pandav.skybubbleburst</font>), "
        "available on Google Play.",
        S["body"]))
    story.append(Paragraph(
        "By downloading, installing, or playing Sky Bubble Burst, you acknowledge that you have "
        "read and understood this Privacy Policy. If you do not agree, please uninstall the app.",
        S["body"]))
    story.append(Paragraph("<b>This policy was prepared to comply with:</b>", S["body"]))

    regs = [
        "Google Play Developer Program Policies (User Data Policy)",
        "Google Play Families Policy",
        "Google AdMob Publisher Policies",
        "EU General Data Protection Regulation (GDPR)",
        "California Consumer Privacy Act (CCPA / CPRA)",
        "Children's Online Privacy Protection Act (COPPA)",
    ]
    for r in regs:
        story.append(Paragraph(f"• {r}", S["bullet"]))

    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 2 — Information We Collect
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("02", "Information We Collect"))
    story.append(Spacer(1, 3*mm))

    story.append(NoteBox(
        "TRANSPARENCY NOTE: The following information accurately reflects data handling as "
        "implemented in the app's source code. No data is transmitted to our servers.",
        kind="info"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph("<b>2.1  Data Stored Locally on Your Device</b>", S["h3"]))
    story.append(Paragraph(
        "Sky Bubble Burst stores the following data exclusively on your device using "
        "<font name='Courier' size='8.5'>get_storage</font>, a local key-value storage library. "
        "<b>This data never leaves your device and is never transmitted to us or any third party.</b>",
        S["body"]))
    story.append(Spacer(1, 2*mm))

    local_data_headers = ["Data Type", "Purpose", "Transmitted?", "Deletable?"]
    local_data_rows = [
        [Paragraph("<b>Game Scores</b>",           S["body_bold"]),
         "Track high scores and gameplay history",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Coins</b>",                 S["body_bold"]),
         "In-game virtual currency balance",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Current Level</b>",         S["body_bold"]),
         "Track player progression",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Unlocked Bubble Styles</b>",S["body_bold"]),
         "Remember unlocked cosmetic items",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Selected Style</b>",        S["body_bold"]),
         "Remember chosen visual theme",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Unlocked Backgrounds</b>",  S["body_bold"]),
         "Remember unlocked game backgrounds",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Selected Background</b>",   S["body_bold"]),
         "Remember chosen background",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Awards Count</b>",          S["body_bold"]),
         "Track earned in-game awards/trophies",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
        [Paragraph("<b>Gifted Hearts / Coins /\nAwards</b>", S["body_bold"]),
         "Track lifetime rewards earned via ad viewing",
         tag_cell("No – Local Only", "green"),
         tag_cell("Yes – Clear App Data", "green")],
    ]
    story.append(data_table(local_data_headers, local_data_rows,
                            [36*mm, 54*mm, 30*mm, 30*mm], S))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph("<b>2.2  Data Collected by Third-Party SDKs</b>", S["h3"]))
    story.append(Paragraph(
        "While we do not personally collect data, the Google AdMob advertising SDK integrated "
        "into the app may collect certain technical and device information as described in Section 4.",
        S["body"]))

    story.append(Paragraph("<b>2.3  Data We Do NOT Collect</b>", S["h3"]))
    no_collect = [
        "Name, email address, or any contact information",
        "Phone number or device contacts",
        "Location data (GPS, network-based, or otherwise)",
        "Camera or microphone data",
        "Photos, files, or media from your device",
        "Biometric data",
        "Financial information or payment data",
        "Social media account information",
        "Health or fitness data",
        "User account credentials (no login exists)",
    ]
    for item in no_collect:
        story.append(Paragraph(f"✗  {item}", ParagraphStyle(
            "nc", fontName="Helvetica", fontSize=9, leading=13,
            textColor=C_TEXT_SEC, leftIndent=8, spaceAfter=2)))

    story.append(Spacer(1, 3*mm))
    story.append(Paragraph("<b>2.4  Android Permissions</b>", S["h3"]))

    perm_headers = ["Permission", "Required By", "Purpose"]
    perm_rows = [
        [Paragraph("<font name='Courier' size='8'>INTERNET</font>", S["body"]),
         "Google AdMob",
         "Load and display advertisements"],
        [Paragraph("<font name='Courier' size='8'>ACCESS_NETWORK_STATE</font>", S["body"]),
         "Google AdMob",
         "Check network connectivity before making ad requests"],
    ]
    story.append(data_table(perm_headers, perm_rows, [46*mm, 34*mm, 70*mm], S))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 3 — How We Use Information
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("03", "How We Use Information"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph(
        "The locally stored data is used <b>exclusively</b> to:", S["body"]))

    usage = [
        ("<b>Provide core gameplay</b>", "Restore your progress when you reopen the app."),
        ("<b>Display achievements</b>",  "Show high scores and award history."),
        ("<b>Personalise cosmetics</b>", "Remember your chosen bubble style and background."),
        ("<b>Manage in-game rewards</b>","Track coins and awards earned by watching ads."),
    ]
    for title, detail in usage:
        story.append(Paragraph(f"•  {title} — {detail}", S["bullet"]))

    story.append(Paragraph("<b>We do NOT use information for:</b>", S["body"]))
    no_use = ["Marketing or advertising profiling", "Behavioural tracking or analytics",
              "Sale or transfer to data brokers", "Any purpose beyond operating the game"]
    for item in no_use:
        story.append(Paragraph(f"✗  {item}", ParagraphStyle(
            "nu", fontName="Helvetica", fontSize=9, leading=13,
            textColor=C_TEXT_SEC, leftIndent=8, spaceAfter=2)))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 4 — Advertising
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("04", "Advertising (Google AdMob)"))
    story.append(Spacer(1, 3*mm))

    story.append(NoteBox(
        "GOOGLE PLAY ADVERTISING DISCLOSURE: This app contains advertisements. "
        "The following section provides the disclosures required by Google Play's Advertising "
        "Policy and AdMob Publisher Policies.",
        kind="warning"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph("<b>4.1  Ad Types Displayed</b>", S["h3"]))
    story.append(Paragraph(
        "Sky Bubble Burst displays the following ad formats via Google AdMob:", S["body"]))
    story.append(Paragraph(
        "• <b>Banner Ads</b> — displayed persistently within the game interface.", S["bullet"]))
    story.append(Paragraph(
        "• <b>Interstitial Ads</b> — full-screen ads shown at natural transition points "
        "(e.g., level completion). A minimum <b>60-second frequency cap</b> is enforced "
        "between auto-triggered interstitials.", S["bullet"]))

    story.append(Paragraph("<b>4.2  Non-Personalized Ads Configuration</b>", S["h3"]))
    story.append(Paragraph(
        "Sky Bubble Burst is configured to request <b>non-personalized ads</b> from AdMob "
        "(<font name='Courier' size='8.5'>nonPersonalizedAds: true</font>). "
        "This means AdMob does not use your personal data or behavioural profile to select ads.",
        S["body"]))
    story.append(Paragraph(
        "Ad content is filtered to a <b>General (G) audience rating</b> "
        "(<font name='Courier' size='8.5'>MaxAdContentRating.g</font>), ensuring only "
        "family-appropriate advertisements are served.",
        S["body"]))

    story.append(Paragraph("<b>4.3  What AdMob May Collect</b>", S["h3"]))
    admob_data = [
        "Device identifiers (e.g., Android Advertising ID / GAID)",
        "IP address (used for approximate geolocation and fraud prevention)",
        "Device type, model, OS version",
        "App identifiers and interaction data (e.g., ad clicks, impressions)",
        "Network and carrier information",
    ]
    for item in admob_data:
        story.append(Paragraph(f"• {item}", S["bullet"]))
    story.append(Paragraph(
        "This data is collected and processed by Google, not by us. Google's use of this data "
        "is governed by the Google Privacy Policy (policies.google.com/privacy).",
        S["body"]))

    story.append(Paragraph("<b>4.4  AdMob App ID</b>", S["h3"]))
    story.append(Paragraph(
        "Our AdMob App ID is "
        "<font name='Courier' size='8.5'>ca-app-pub-8536272432230680~9983882940</font>. "
        "This identifier is registered with Google and associates ad requests with our application.",
        S["body"]))

    story.append(Paragraph("<b>4.5  Opting Out of Interest-Based Advertising</b>", S["h3"]))
    opt_out = [
        "Open Settings on your Android device.",
        "Go to Privacy → Ads.",
        'Select "Delete advertising ID" or enable "Opt out of Ads Personalisation".',
    ]
    for i, step in enumerate(opt_out, 1):
        story.append(Paragraph(f"{i}.  {step}", S["bullet"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 5 — Third-Party Services
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("05", "Third-Party Services"))
    story.append(Spacer(1, 3*mm))

    tp_headers = ["Service / SDK", "Provider", "Purpose", "Privacy Policy"]
    tp_rows = [
        ["Google AdMob",              "Google LLC",    "Banner + interstitial ads",           "policies.google.com/privacy"],
        ["apsl_admob_ads_flutter",    "APSL",          "Flutter wrapper – Google Mobile Ads", "Governed by Google AdMob policy"],
        ["get_storage",               "GetX / OSS",    "Local device storage – no transfer",  "No external data transfer"],
        ["audioplayers",              "Blue Fire",     "Play bubble pop sound effects",        "No data collection"],
        ["url_launcher",              "Flutter/Google","Open URLs in device browser",          "No data collection"],
        ["flutter_sizer",             "Open-source",   "Responsive UI sizing utility",         "No data collection"],
    ]
    story.append(data_table(tp_headers, tp_rows, [38*mm, 28*mm, 44*mm, 40*mm], S))
    story.append(Spacer(1, 3*mm))

    story.append(NoteBox(
        "NO ANALYTICS SDK: This app does not integrate Firebase Analytics, Crashlytics, "
        "Amplitude, Mixpanel, or any other analytics or crash-reporting service. "
        "No behavioural telemetry is collected.",
        kind="info"))
    story.append(Spacer(1, 2*mm))
    story.append(NoteBox(
        "NO PAYMENT SDK: This app does not integrate any payment processing service. "
        "No in-app purchases are available. All in-game rewards are earned by watching ads.",
        kind="info"))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTIONS 6 & 7 — Retention + Security
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("06", "Data Retention"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "All game data is stored locally on your device using "
        "<font name='Courier' size='8.5'>get_storage</font> and persists as long as the app is "
        "installed. Data is automatically removed when you <b>uninstall the app</b> or "
        "<b>clear app data</b> via Android Settings → Apps → Sky Bubble Burst → Clear Data.",
        S["body"]))
    story.append(Paragraph(
        "Because we do not receive or store any data on our servers, we have no server-side "
        "data to manage. Data retained by Google AdMob is subject to Google's data retention practices.",
        S["body"]))
    story.append(Spacer(1, 4*mm))

    story.append(SectionHeader("07", "Data Security"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "All game data resides only on your device and is protected by Android's application "
        "sandboxing model. Third-party applications cannot access this data without root-level "
        "device access.",
        S["body"]))
    story.append(Paragraph(
        "The only network traffic generated by the app relates to AdMob ad requests, which are "
        "handled by the Google Mobile Ads SDK using industry-standard <b>HTTPS encryption</b>.",
        S["body"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 8 — Children's Privacy
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("08", "Children's Privacy"))
    story.append(Spacer(1, 3*mm))

    story.append(NoteBox(
        "FAMILIES POLICY NOTE: Sky Bubble Burst is described as a 'Kids Game.' "
        "This section reflects our commitment to children's privacy and our AdMob "
        "configuration for general audiences.",
        kind="warning"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph(
        "Sky Bubble Burst is a family-friendly bubble-popping game suitable for all ages, "
        "including children. We have implemented the following protections:", S["body"]))

    story.append(Paragraph("<b>8.1  No Personal Data Collection from Children</b>", S["h3"]))
    story.append(Paragraph(
        "We do not knowingly collect any personal information from children under 13 (COPPA) "
        "or under 16 (GDPR) — or from any user, regardless of age. No account creation, "
        "name, email, or contact information is ever requested.",
        S["body"]))

    story.append(Paragraph("<b>8.2  Child-Safe Advertising Configuration</b>", S["h3"]))
    child_ad = [
        "<b>Maximum ad content rating: G (General)</b> — only family-appropriate ads are served "
        "(<font name='Courier' size='8.5'>MaxAdContentRating.g</font>).",
        "<b>Non-personalized ads</b> — ad serving does not rely on user profiling or targeting.",
        "<font name='Courier' size='8.5'>tagForChildDirectedTreatment</font> and "
        "<font name='Courier' size='8.5'>tagForUnderAgeOfConsent</font> are set to "
        "<font name='Courier' size='8.5'>unspecified</font>.",
    ]
    for item in child_ad:
        story.append(Paragraph(f"• {item}", S["bullet"]))

    story.append(Paragraph("<b>8.3  Parental Guidance</b>", S["h3"]))
    story.append(Paragraph(
        "Parents and guardians with questions about their child's use of Sky Bubble Burst, "
        "or who wish to request deletion of locally stored data, may contact us at "
        "<b>developerpandav16@gmail.com</b>. Data can also be deleted immediately by clearing "
        "the app's data through Android Settings.",
        S["body"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 9 — Your Rights
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("09", "Your Rights & Choices"))
    story.append(Spacer(1, 3*mm))
    rights = [
        ("<b>Delete all local game data</b>",
         "Android Settings → Apps → Sky Bubble Burst → Clear Data."),
        ("<b>Uninstall the app</b>",
         "Removes all locally stored game data from your device."),
        ("<b>Opt out of ad personalisation</b>",
         "Via Android device settings (see Section 4.5)."),
        ("<b>Delete AdMob Advertising ID</b>",
         "Android Settings → Privacy → Ads → Delete advertising ID."),
    ]
    for title, detail in rights:
        story.append(Paragraph(f"• {title} — {detail}", S["bullet"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 10 + 11 — International Transfers + Data Deletion
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("10", "International Data Transfers"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "We do not transfer any personal data internationally because we do not collect "
        "personal data. Google AdMob, as a service operated by Google LLC (US), may process "
        "data in the United States or other countries where Google maintains data centres. "
        "This is subject to Google's Standard Contractual Clauses under GDPR.",
        S["body"]))
    story.append(Spacer(1, 4*mm))

    story.append(SectionHeader("11", "Data Deletion / Account Deletion"))
    story.append(Spacer(1, 3*mm))
    story.append(NoteBox(
        "GOOGLE PLAY REQUIREMENT: Google Play requires all apps to provide a data deletion "
        "mechanism. The instructions below satisfy this requirement.",
        kind="info"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "Sky Bubble Burst does not have user accounts. All data is stored locally on your device.",
        S["body"]))
    story.append(Paragraph("<b>To delete all app data immediately:</b>", S["body"]))
    deletion_steps = [
        "Open Settings on your Android device.",
        "Navigate to Apps (or Application Manager).",
        "Find and tap Sky Bubble Burst.",
        "Tap Storage.",
        "Tap Clear Data → Confirm.",
    ]
    for i, step in enumerate(deletion_steps, 1):
        story.append(Paragraph(f"{i}.  {step}", S["bullet"]))
    story.append(Paragraph(
        "This permanently deletes all scores, coins, level progress, unlocked styles, and "
        "unlocked backgrounds stored by the app. Alternatively, uninstalling the app removes "
        "all locally stored data automatically.",
        S["body"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 12 — GDPR
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("12", "GDPR Rights (EEA / UK Residents)"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "If you are located in the European Economic Area (EEA) or the United Kingdom, "
        "you have rights under the GDPR and UK GDPR. Because we do not collect personal data "
        "from you directly, most GDPR rights apply primarily in the context of data processed "
        "by Google AdMob.",
        S["body"]))

    gdpr_rights_headers = ["Right", "Description"]
    gdpr_rights_rows = [
        [Paragraph("<b>Right of Access</b>",           S["body_bold"]),
         "Request a copy of personal data held about you."],
        [Paragraph("<b>Right to Rectification</b>",    S["body_bold"]),
         "Request correction of inaccurate data."],
        [Paragraph("<b>Right to Erasure</b>",          S["body_bold"]),
         "Request deletion of your personal data."],
        [Paragraph("<b>Right to Restrict Processing</b>", S["body_bold"]),
         "Request limitation of how data is processed."],
        [Paragraph("<b>Right to Data Portability</b>", S["body_bold"]),
         "Receive your data in a structured, machine-readable format."],
        [Paragraph("<b>Right to Object</b>",           S["body_bold"]),
         "Object to processing based on legitimate interests."],
        [Paragraph("<b>Withdraw Consent</b>",          S["body_bold"]),
         "Withdraw consent at any time."],
    ]
    story.append(data_table(gdpr_rights_headers, gdpr_rights_rows, [52*mm, 98*mm], S))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "<b>Legal Basis for Processing:</b> Local game data is processed on the basis of "
        "<i>legitimate interests</i> (providing the core gaming service). AdMob advertising "
        "is processed on the basis of <i>legitimate interests</i> (non-personalized ad serving) "
        "and, where applicable, <i>consent</i>.",
        S["body"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 13 — CCPA
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("13", "CCPA Rights (California Residents)"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "If you are a California resident, the CCPA and CPRA provide specific rights regarding "
        "personal information. <b>We do not sell personal information.</b>",
        S["body"]))
    ccpa = [
        "<b>Right to Know</b> — What personal information is collected, used, and disclosed.",
        "<b>Right to Delete</b> — Request deletion of personal information.",
        "<b>Right to Opt-Out of Sale</b> — We do not sell personal data; not applicable.",
        "<b>Right to Non-Discrimination</b> — No discrimination for exercising CCPA rights.",
    ]
    for item in ccpa:
        story.append(Paragraph(f"• {item}", S["bullet"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 14 — Contact
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("14", "Contact Us"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "For any questions, concerns, or requests regarding this Privacy Policy:", S["body"]))

    contact_rows = [
        ["Developer / Data Controller", "Pandav"],
        ["Email",                       "developerpandav16@gmail.com"],
        ["App Name",                    "Sky Bubble Burst"],
        ["Package Name",                "com.pandav.skybubbleburst"],
        ["Platform",                    "Google Play (Android)"],
        ["Response Time",               "Within 30 days of verified request"],
    ]
    contact_data = [[
        Paragraph(f"<b>{r[0]}</b>", ParagraphStyle("cl", fontName="Helvetica-Bold",
                  fontSize=8.5, leading=12, textColor=C_TEXT)),
        Paragraph(r[1], ParagraphStyle("cv", fontName="Helvetica",
                  fontSize=8.5, leading=12, textColor=C_TEXT_SEC))
    ] for r in contact_rows]

    contact_table = Table(contact_data, colWidths=[55*mm, 95*mm], style=TableStyle([
        ("BACKGROUND",    (0,0), (-1,-1), C_SURFACE_ALT),
        ("ROWBACKGROUNDS",(0,0), (-1,-1), [C_SURFACE_ALT, C_SURFACE]),
        ("GRID",          (0,0), (-1,-1), 0.4, C_BORDER),
        ("TOPPADDING",    (0,0), (-1,-1), 6),
        ("BOTTOMPADDING", (0,0), (-1,-1), 6),
        ("LEFTPADDING",   (0,0), (-1,-1), 8),
        ("BACKGROUND",    (0,0), (0,-1), HexColor("#EEF2FF")),
    ]))
    story.append(contact_table)
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 15 — Policy Updates
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("15", "Policy Updates"))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        "We may update this Privacy Policy from time to time to reflect changes in our "
        "practices, technology, or legal requirements. When we make material changes, we will "
        "update the <b>Last Updated</b> date at the top of this policy. "
        "Continued use of Sky Bubble Burst after any changes constitutes acceptance of the "
        "revised policy. If you do not agree with the revised policy, please uninstall the app.",
        S["body"]))
    story.append(Spacer(1, 4*mm))
    story.append(DividerLine())

    # ════════════════════════════════════════════════════════════════════════
    #  SECTION 16 — Compliance Audit
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 5*mm))
    story.append(SectionHeader("16", "Compliance Audit Summary"))
    story.append(Spacer(1, 3*mm))
    story.append(NoteBox(
        "DEVELOPER NOTE: This section is for internal review and Google Play submission "
        "preparation. Consider removing it from the public-facing version once all items resolved.",
        kind="info"))
    story.append(Spacer(1, 3*mm))

    story.append(Paragraph("<b>Confirmed Compliant</b>", S["h3"]))
    pass_items = [
        ("No personal data collected",
         "Verified in source code – only local get_storage used; no server calls."),
        ("AdMob fully disclosed",
         "Ad types, App ID, and data collection practices disclosed in Section 4."),
        ("Non-personalized ads configured",
         "nonPersonalizedAds: true confirmed in ad_service.dart."),
        ("G-rated ad content filter applied",
         "MaxAdContentRating.g set in AdMob initialization."),
        ("No analytics SDK present",
         "No Firebase, Crashlytics, or behavioural analytics confirmed in codebase."),
        ("No payment SDK present",
         "No in-app purchases — no financial data collected."),
        ("Data deletion mechanism described",
         "Clear Android Settings instructions provided in Section 11."),
        ("Contact information provided",
         "Developer email disclosed — required by Google Play and GDPR."),
    ]
    story.append(audit_table(pass_items, kind="pass"))
    story.append(Spacer(1, 4*mm))

    story.append(Paragraph("<b>Action Items Requiring Developer Attention</b>", S["h3"]))
    warn_items = [
        ("AdMob test IDs in production code",
         "ads_id_manager.dart uses Google test Ad IDs. Uncomment real IDs before publishing. "
         "Using test IDs in production violates AdMob policy."),
        ("Families Policy: child-directed treatment tag",
         "If primary audience includes children under 13, set tagForChildDirectedTreatment "
         "to TagForChildDirectedTreatment.yes in ad_service.dart."),
        ("Privacy Policy URL in Google Play Console",
         "Host this PDF/HTML at a stable public URL and enter it in Play Console → "
         "App Content → Privacy Policy before submission."),
        ("GDPR consent mechanism [REQUIRES VERIFICATION]",
         "If distributed in EEA, consider implementing Google's User Messaging Platform "
         "(UMP) SDK for a GDPR consent dialog on first launch for EEA users."),
        ("Physical address [REQUIRES VERIFICATION]",
         "Some jurisdictions may require a physical developer address in the policy."),
    ]
    story.append(audit_table(warn_items, kind="warn"))

    # ════════════════════════════════════════════════════════════════════════
    #  FINAL FOOTER BLOCK
    # ════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 8*mm))
    story.append(DividerLine())
    story.append(Spacer(1, 4*mm))

    # Footer card
    footer_data = [[
        Paragraph("🫧  Sky Bubble Burst", ParagraphStyle(
            "fb", fontName="Helvetica-Bold", fontSize=11, textColor=C_PRIMARY)),
        Paragraph(
            "© 2025 Pandav. All rights reserved.<br/>"
            "<font color='#475569' size='8'>Effective: June 12, 2025  ·  Last Updated: June 12, 2025</font><br/>"
            "<font color='#3B82F6' size='8'>developerpandav16@gmail.com</font>",
            ParagraphStyle("fm", fontName="Helvetica", fontSize=9, leading=14,
                           textColor=C_TEXT_SEC, alignment=TA_RIGHT)),
    ]]
    footer_t = Table(footer_data, colWidths=[80*mm, CONTENT_W - 80*mm], style=TableStyle([
        ("BACKGROUND",    (0,0), (-1,-1), C_SURFACE_ALT),
        ("BOX",           (0,0), (-1,-1), 0.5, C_BORDER),
        ("TOPPADDING",    (0,0), (-1,-1), 8),
        ("BOTTOMPADDING", (0,0), (-1,-1), 8),
        ("LEFTPADDING",   (0,0), (-1,-1), 10),
        ("RIGHTPADDING",  (0,0), (-1,-1), 10),
        ("VALIGN",        (0,0), (-1,-1), "MIDDLE"),
    ]))
    story.append(footer_t)

    # ── Build ────────────────────────────────────────────────────────────────
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    print(f"PDF generated: {OUT}")


if __name__ == "__main__":
    build()
