#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
const mode = args[0];
const filePath = args[1];

function runAct(command, args) {
    console.log(`🚀 Running: act ${command} ${args.join(' ')}`);
    console.log('='.repeat(50));
    
    // Create a temporary secrets file from .env
    const fs = require('fs');
    const envContent = fs.readFileSync('.env', 'utf8');
    const secrets = [];
    
    envContent.split('\n').forEach(line => {
        if (line.includes('DOCKER_ACCESS_TOKEN=')) {
            const token = line.split('=')[1];
            secrets.push(`DOCKER_ACCESS_TOKEN=${token}`);
        }
    });
    
    if (secrets.length > 0) {
        fs.writeFileSync('.temp-secrets', secrets.join('\n'));
        args.push('--secret-file', '.temp-secrets');
    }
    
    const actProcess = spawn('act', [command, ...args], {
        stdio: 'inherit',
        shell: true,
        cwd: process.cwd()
    });

    actProcess.on('close', (code) => {
        // Clean up temporary secrets file
        if (fs.existsSync('.temp-secrets')) {
            fs.unlinkSync('.temp-secrets');
        }
        
        console.log('='.repeat(50));
        if (code === 0) {
            console.log('✅ Act command completed successfully');
        } else {
            console.log(`❌ Act command failed with exit code ${code}`);
        }
    });

    actProcess.on('error', (error) => {
        console.error('❌ Error running act command:', error.message);
        console.log('💡 Make sure you have act installed: https://github.com/nektos/act');
    });
}

function validateWorkflowFile(filePath) {
    if (!filePath) {
        console.error('❌ No file path provided');
        return false;
    }
    
    const ext = path.extname(filePath).toLowerCase();
    if (ext !== '.yml' && ext !== '.yaml') {
        console.error('❌ File must be a YAML workflow file (.yml or .yaml)');
        return false;
    }
    
    if (!filePath.includes('.github/workflows/')) {
        console.error('❌ File must be in .github/workflows/ directory');
        return false;
    }
    
    return true;
}

switch (mode) {
    case 'dryrun':
        if (validateWorkflowFile(filePath)) {
            runAct('push', [
                '--workflows', filePath,
                '--env-file', '.env',
                '--dryrun'
            ]);
        }
        break;
        
    case 'live':
        if (validateWorkflowFile(filePath)) {
            runAct('push', [
                '--workflows', filePath,
                '--env-file', '.env'
            ]);
        }
        break;
        
    case 'test-env':
        runAct('push', [
            '--workflows', '.github/workflows/test-env.yml',
            '--env-file', '.env'
        ]);
        break;
        
    case 'test-docker':
        runAct('push', [
            '--workflows', '.github/workflows/test-docker.yml',
            '--env-file', '.env'
        ]);
        break;
        
    default:
        console.log('🎯 Available modes:');
        console.log('  dryrun    - Run current workflow in dry-run mode');
        console.log('  live      - Run current workflow in live mode');
        console.log('  test-env  - Test environment variables');
        console.log('  test-docker - Test Docker login');
        console.log('');
        console.log('💡 Usage: node run-act.js <mode> [filepath]');
        console.log('💡 Make sure you have a .env file with your configuration');
}
