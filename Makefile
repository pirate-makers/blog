# Resume PDF generation (pandoc + weasyprint).
# PDFs land in static/ so Hugo publishes them with the site.
# Requires: brew install pandoc weasyprint

PANDOC          ?= pandoc
WEASYPRINT      ?= weasyprint
RESUME_CSS      := resume.css
RESUME_TITLE_EN := Sebastien (Prune) THOMAS — Resume
RESUME_TITLE_FR := Sebastien (Prune) THOMAS — CV

.PHONY: help resume resume-en resume-fr

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

resume: resume-en resume-fr ## Build both resume PDFs

resume-en: static/resume-en.pdf ## Build the English resume PDF

resume-fr: static/resume-fr.pdf ## Build the French resume PDF

static/resume-en.pdf: content/resume.md $(RESUME_CSS)
	@mkdir -p $(@D)
	$(call md2pdf,$<,$@,$(RESUME_TITLE_EN))

static/resume-fr.pdf: content/resume.fr.md $(RESUME_CSS)
	@mkdir -p $(@D)
	$(call md2pdf,$<,$@,$(RESUME_TITLE_FR))

# Strip Hugo front matter (+++ ... +++), then markdown -> HTML -> PDF.
define md2pdf
	tmp=$$(mktemp -d); \
	awk 'BEGIN{fm=0} /^\+\+\+/{fm=!fm; next} !fm{print}' $(1) > $$tmp/body.md; \
	$(PANDOC) $$tmp/body.md --standalone \
		--css $(CURDIR)/$(RESUME_CSS) \
		--metadata pagetitle="$(3)" \
		-o $$tmp/resume.html; \
	$(WEASYPRINT) $$tmp/resume.html $(2); \
	rm -rf $$tmp
endef
