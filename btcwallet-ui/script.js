// BTC Wallet functionality
class BTCWalletApp {
    constructor() {
        // Use localhost when running locally, host.docker.internal when running in Docker
        if (window.location.hostname === '') {
            this.baseUrl = 'http://localhost:8001/api/btcwallet';
        } else {
            this.baseUrl = window.location.hostname === 'localhost' ? 'http://localhost:8001/api/btcwallet' : 'http://host.docker.internal:8001/api/btcwallet';
        }
        // this.baseUrl = window.location.hostname === 'localhost' ? 'http://localhost:8001/api/btcwallet' : 'http://host.docker.internal:8001/api/btcwallet';
        this.walletAddressElement = document.getElementById('walletAddress');
        this.walletBalanceElement = document.getElementById('walletBalance');
        this.walletDateElement = document.getElementById('walletDate');
        this.walletSelector = document.getElementById('walletSelector');
        
        this.init();
    }

    async init() {
        try {
            await this.loadWallet();
            this.setupWalletSelector();
        } catch (error) {
            console.error('Error loading wallet:', error);
            this.showError();
        }
    }

    async loadWallet(address = null) {
        try {
            const url = address ? `${this.baseUrl}/address/${address}` : `${this.baseUrl}/first`;
            console.log('Fetching wallet from:', url);
            console.log('Base URL:', this.baseUrl);
            
            const response = await fetch(url);
            console.log('Response status:', response.status);
            console.log('Response headers:', response.headers);
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            console.log('Wallet data received:', data);
            this.displayWallet(data);
        } catch (error) {
            console.error('Failed to fetch wallet:', error);
            console.error('Error details:', error.message);
            this.showError();
        }
    }

    setupWalletSelector() {
        if (this.walletSelector) {
            this.walletSelector.addEventListener('change', async (event) => {
                const selectedAddress = event.target.value;
                if (selectedAddress) {
                    await this.loadWallet(selectedAddress);
                }
            });
        }
    }

    displayWallet(walletData) {
        // Add fade-in animation
        this.walletAddressElement.style.opacity = '0';
        this.walletBalanceElement.style.opacity = '0';
        this.walletDateElement.style.opacity = '0';

        // Update content
        this.walletAddressElement.textContent = walletData.address;
        this.walletBalanceElement.textContent = `Balance: ${walletData.balance}`;
        
        // Format and display date
        if (walletData.date) {
            const date = new Date(walletData.date);
            const formattedDate = date.toLocaleDateString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
            this.walletDateElement.textContent = `Date: ${formattedDate}`;
        }

        // Fade in the content
        setTimeout(() => {
            this.walletAddressElement.style.transition = 'opacity 0.8s ease-in-out';
            this.walletBalanceElement.style.transition = 'opacity 0.8s ease-in-out';
            this.walletDateElement.style.transition = 'opacity 0.8s ease-in-out';
            
            this.walletAddressElement.style.opacity = '1';
            this.walletBalanceElement.style.opacity = '1';
            this.walletDateElement.style.opacity = '1';
        }, 100);
    }

    showError() {
        this.walletAddressElement.innerHTML = `
            <div style="display: flex; align-items: center; justify-content: center; gap: 10px;">
                <div class="loading">
                    <div></div>
                    <div></div>
                </div>
                <span>Unable to load wallet information</span>
            </div>
        `;
        this.walletBalanceElement.textContent = 'Please try again later';
        this.walletDateElement.textContent = '';
    }

    // Method to refresh wallet (can be called manually if needed)
    async refreshWallet() {
        this.walletAddressElement.textContent = 'Loading wallet information...';
        this.walletBalanceElement.textContent = '—';
        this.walletDateElement.textContent = '';
        
        await this.loadWallet();
    }

    // Method to load wallet for specific address
    async loadWalletForAddress(address) {
        this.walletAddressElement.textContent = 'Loading wallet information...';
        this.walletBalanceElement.textContent = '—';
        this.walletDateElement.textContent = '';
        
        await this.loadWallet(address);
    }
}

// Initialize the app when DOM is loaded
let btcWalletApp;

document.addEventListener('DOMContentLoaded', () => {
    btcWalletApp = new BTCWalletApp();
    
    const walletCard = document.querySelector('.wallet-card');
    
    // Add click to refresh functionality
    walletCard.addEventListener('click', async () => {
        // Add a subtle click effect
        walletCard.style.transform = 'scale(0.98)';
        setTimeout(() => {
            walletCard.style.transform = '';
        }, 150);
        
        // Refresh the wallet using the existing app instance
        await btcWalletApp.refreshWallet();
    });
    
    // Add hover effect for better UX
    walletCard.style.cursor = 'pointer';
    
    // Add a subtle tooltip
    walletCard.title = 'Click to refresh wallet';
});