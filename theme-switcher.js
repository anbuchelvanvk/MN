// ==========================================================================
// MN FAMILY - UNIVERSAL COLOR COMBO SWITCHER
// Supports:
// 1. Burgundy & Champagne Sand (Combo 1)
// 2. Midnight Onyx & Warm Sand (Combo 2)
// 3. Royal Navy & Classic Gold (Signature MN Palette)
// ==========================================================================

(function() {
  // Read theme from URL or localStorage
  const urlParams = new URLSearchParams(window.location.search);
  const themeParam = urlParams.get('theme');
  const savedTheme = themeParam || localStorage.getItem('mn-app-theme') || 'maroon';

  function applyTheme(themeName) {
    document.documentElement.setAttribute('data-theme', themeName);
    localStorage.setItem('mn-app-theme', themeName);
    
    // Update active card states in modal
    document.querySelectorAll('.theme-option-card').forEach(card => {
      if (card.getAttribute('data-theme-key') === themeName) {
        card.classList.add('active');
      } else {
        card.classList.remove('active');
      }
    });

    // Update floating trigger label if present
    const labelEl = document.getElementById('active-theme-label');
    if (labelEl) {
      const labels = {
        'maroon': '🍷 Burgundy & Sand',
        'onyx': '🖤 Onyx & Sand',
        'navy': '👑 Navy & Gold'
      };
      labelEl.textContent = labels[themeName] || 'Palette';
    }
  }

  // Apply immediately on script run
  applyTheme(savedTheme);

  // Inject Floating Button and Modal into DOM after loaded
  document.addEventListener('DOMContentLoaded', () => {
    // 1. Create Floating Button
    const triggerBtn = document.createElement('button');
    triggerBtn.className = 'theme-trigger-btn';
    triggerBtn.id = 'theme-trigger-btn';
    triggerBtn.title = 'Change Color Combination';
    triggerBtn.onclick = () => openThemeModal();
    triggerBtn.innerHTML = `
      <span class="theme-swatch-dot"></span>
      <span id="active-theme-label">Palette</span>
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="6 9 12 15 18 9"></polyline></svg>
    `;
    document.body.appendChild(triggerBtn);

    // 2. Create Modal
    const modalBackdrop = document.createElement('div');
    modalBackdrop.className = 'modal-backdrop';
    modalBackdrop.id = 'modal-theme-switcher';
    modalBackdrop.onclick = (e) => {
      if (e.target === modalBackdrop) closeThemeModal();
    };

    modalBackdrop.innerHTML = `
      <div class="modal-sheet">
        <div class="modal-header">
          <h3 class="modal-title">🎨 Select Color Theme</h3>
          <button class="modal-close" onclick="closeThemeModal()">✕</button>
        </div>
        <p style="font-size: 12px; color: var(--text-muted); margin-bottom: 8px;">
          Choose your preferred luxury aesthetic palette for MN Jewel Park:
        </p>

        <div class="theme-palette-grid">
          <!-- COMBO 1 -->
          <div class="theme-option-card ${savedTheme === 'maroon' ? 'active' : ''}" data-theme-key="maroon" onclick="selectTheme('maroon')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #580816;"></div>
                <div class="c-right" style="background: #cbb094;"></div>
              </div>
              <div>
                <div class="theme-option-title">Burgundy & Champagne Sand</div>
                <div class="theme-option-desc">Deep Wine Velvet Maroon + Biscuit Sand (Combo 1)</div>
              </div>
            </div>
            <span style="font-size: 16px;">✓</span>
          </div>

          <!-- COMBO 2 -->
          <div class="theme-option-card ${savedTheme === 'onyx' ? 'active' : ''}" data-theme-key="onyx" onclick="selectTheme('onyx')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #000000;"></div>
                <div class="c-right" style="background: #cbb094;"></div>
              </div>
              <div>
                <div class="theme-option-title">Midnight Onyx & Sand Gold</div>
                <div class="theme-option-desc">Jet Black Obsidian + Warm Sand (Combo 2)</div>
              </div>
            </div>
            <span style="font-size: 16px;">✓</span>
          </div>

          <!-- SIGNATURE -->
          <div class="theme-option-card ${savedTheme === 'navy' ? 'active' : ''}" data-theme-key="navy" onclick="selectTheme('navy')">
            <div class="theme-option-left">
              <div class="theme-preview-pill">
                <div class="c-left" style="background: #0f172a;"></div>
                <div class="c-right" style="background: #d4af37;"></div>
              </div>
              <div>
                <div class="theme-option-title">Royal Navy & Classic Gold</div>
                <div class="theme-option-desc">Midnight Blue Charcoal + Metallic Gold</div>
              </div>
            </div>
            <span style="font-size: 16px;">✓</span>
          </div>
        </div>

        <button class="btn-primary btn-full" style="margin-top: 18px;" onclick="closeThemeModal()">Apply & Close</button>
      </div>
    `;
    document.body.appendChild(modalBackdrop);

    // Initial label update
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
        'maroon': 'Theme set to Burgundy & Champagne Sand!',
        'onyx': 'Theme set to Midnight Onyx & Warm Sand!',
        'navy': 'Theme set to Royal Navy & Classic Gold!'
      };
      showToast(names[themeName] || 'Theme updated!');
    }
    setTimeout(() => {
      closeThemeModal();
    }, 250);
  };
})();
