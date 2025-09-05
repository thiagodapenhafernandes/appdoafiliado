// Main application JavaScript file

document.addEventListener('DOMContentLoaded', function() {
  // Mobile sidebar toggle functionality
  const mobileMenuButton = document.getElementById('mobile-menu-button');
  const mobileOverlay = document.getElementById('mobile-sidebar-overlay');
  const closeSidebarButton = document.getElementById('close-sidebar');
  
  if (mobileMenuButton && mobileOverlay) {
    mobileMenuButton.addEventListener('click', function() {
      mobileOverlay.classList.remove('hidden');
    });
  }
  
  if (closeSidebarButton && mobileOverlay) {
    closeSidebarButton.addEventListener('click', function() {
      mobileOverlay.classList.add('hidden');
    });
  }
  
  // Close sidebar when clicking on overlay
  if (mobileOverlay) {
    mobileOverlay.addEventListener('click', function(e) {
      if (e.target === mobileOverlay || e.target.classList.contains('bg-gray-600')) {
        mobileOverlay.classList.add('hidden');
      }
    });
  }
});
