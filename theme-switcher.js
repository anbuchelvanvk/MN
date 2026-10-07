// ==========================================================================
// MN FAMILY - UNIVERSAL COLOR COMBO SWITCHER (4 LUXURY PALETTES)
// 1. Burgundy & Champagne Sand (Combo 1)
// 2. Midnight Onyx & Warm Sand (Combo 2)
// 3. Royal Navy & Classic Gold (Combo 3 / Signature)
// 4. Emerald Royale & Radiant Gold (Combo 4)
// ==========================================================================

(function() {
  const urlParams = new URLSearchParams(window.location.search);
  const themeParam = urlParams.get('theme');
  const savedTheme = themeParam || localStorage.getItem('mn-app-theme') || 'maroon';

  function applyTheme(themeName) {
    document.documentElement.setAttribute('data-theme', themeName);
    localStorage.setItem('mn-app-theme', themeName);
    
    // Update active card states in modal if present
    document.querySelectorAll('.theme-option-card').forEach(card => {
      if (card.getAttribute('data-theme-key') === themeName) {
        card.classList.add('active');
      } else {
        card.classList.remove('active');
      }
    });

    // Update any theme indicators in header
    const headerPill = document.getElementById('header-theme-label');
    if (headerPill) {
      const names = {
        'maroon': 'Burgundy & Sand',
        'onyx': 'Onyx & Sand',
        'navy': 'Navy & Gold',
        'emerald': 'Emerald & Gold'
      };
      headerPill.textContent = names[themeName] || 'Palette';
    }
  }

  // Apply immediately
  applyTheme(savedTheme);

  // Inject Theme Modal into DOM
  document.addEventListener('DOMContentLoaded', () => {
    // Check if modal already exists
    if (document.getElementById('modal-theme-switcher')) return;

    const modalBackdrop = document.createElement('div');
    modalBackdrop.className = 'modal-backdrop';
    modalBackdrop.id = 'modal-theme-switcher';
    modalBackdrop.onclick = (e) => {
      if (e.target === modalBackdrop) closeThemeModal();
    };

    modalBackdrop.innerHTML = `
      <div class="modal-sheet" style="max-height: 85vh; overflow-y: auto;">
        <div class="modal-header">
          <h3 class="modal-title"><i class="fa-solid fa-palette"></i> Select Luxury Color Palette</h3>
          <button class="modal-close" onclick="closeThemeModal()">✕</button>
        </div>
        <p style="font-size: 11.5px; color: var(--text-muted); margin-bottom: 12px;">
          Choose your preferred executive mobile aesthetic palette for MN Jewel Park:
        </p>

        <div class="theme-palette-grid">
          <!-- COMBO 1 -->
          <div class="theme-option-card ${savedTheme === 'maroon' ? 'active' : ''}" data-theme-key="maroon" onclick="selectTheme('maroon')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #580816;"></div>
                <div class="c-right" style="background: #dfc8af;"></div>
              </div>
              <div>
                <div class="theme-option-title">Combo 1: Burgundy & Champagne Sand</div>
                <div class="theme-option-desc">Deep Wine Velvet + Warm Biscuit Sand</div>
              </div>
            </div>
            <span class="theme-chk-icon"><i class="fa-solid fa-check"></i></span>
          </div>

          <!-- COMBO 2 -->
          <div class="theme-option-card ${savedTheme === 'onyx' ? 'active' : ''}" data-theme-key="onyx" onclick="selectTheme('onyx')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #0a0a0d;"></div>
                <div class="c-right" style="background: #dfc8af;"></div>
              </div>
              <div>
                <div class="theme-option-title">Combo 2: Midnight Onyx & Warm Sand</div>
                <div class="theme-option-desc">Jet Black Obsidian + Warm Sand</div>
              </div>
            </div>
            <span class="theme-chk-icon"><i class="fa-solid fa-check"></i></span>
          </div>

          <!-- COMBO 3 -->
          <div class="theme-option-card ${savedTheme === 'navy' ? 'active' : ''}" data-theme-key="navy" onclick="selectTheme('navy')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #0f172a;"></div>
                <div class="c-right" style="background: #d4af37;"></div>
              </div>
              <div>
                <div class="theme-option-title">Combo 3: Royal Navy & Classic Gold</div>
                <div class="theme-option-desc">Midnight Blue Charcoal + Metallic Gold</div>
              </div>
            </div>
            <span class="theme-chk-icon"><i class="fa-solid fa-check"></i></span>
          </div>

          <!-- COMBO 4 -->
          <div class="theme-option-card ${savedTheme === 'emerald' ? 'active' : ''}" data-theme-key="emerald" onclick="selectTheme('emerald')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #044330;"></div>
                <div class="c-right" style="background: #eab308;"></div>
              </div>
              <div>
                <div class="theme-option-title">Combo 4: Emerald Royale & Radiant Gold</div>
                <div class="theme-option-desc">Deep Indian Emerald + Radiant Temple Gold</div>
              </div>
            </div>
            <span class="theme-chk-icon"><i class="fa-solid fa-check"></i></span>
          </div>
        </div>

        <button class="btn-primary btn-full" style="margin-top: 14px;" onclick="closeThemeModal()">Apply Palette & Close</button>
      </div>
    `;
    document.body.appendChild(modalBackdrop);
    applyTheme(savedTheme);
  });

  window.openThemeModal = function() {
    const m = document.getElementById('modal-theme-switcher');
    if (m) m.classList.add('active');
  };

  window.closeThemeModal = function() {
    const m = document.getElementById('modal-theme-switcher');
    if (m) m.classList.remove('active');
  };

  window.selectTheme = function(themeName) {
    applyTheme(themeName);
    if (typeof showToast === 'function') {
      const names = {
        'maroon': 'Theme set to Burgundy & Champagne Sand',
        'onyx': 'Theme set to Midnight Onyx & Warm Sand',
        'navy': 'Theme set to Royal Navy & Classic Gold',
        'emerald': 'Theme set to Emerald Royale & Radiant Gold'
      };
      showToast(names[themeName] || 'Theme updated');
    }
    setTimeout(() => {
      closeThemeModal();
    }, 220);
  };
})();
